#!/bin/bash

# AFT Account Creation Monitor
# Run this script to check the status of bulk account creation

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 AFT ACCOUNT CREATION MONITOR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Configuration
MGMT_ACCOUNT="535355705679"
AFT_ACCOUNT="809574937450"
AFT_REGION="ap-south-1"

echo "📋 Looking for accounts: Student01, Student02, Student03"
echo ""

# Check 1: AWS Organizations (Management Account)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  Checking AWS Organizations (Management Account $MGMT_ACCOUNT)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# List all accounts and filter for Student accounts
aws organizations list-accounts \
  --query 'Accounts[?contains(Name, `Student`)].{Name:Name, Email:Email, Status:Status, Id:Id}' \
  --output table 2>/dev/null || echo "⚠️  Unable to access Organizations. Check credentials."

echo ""

# Check 2: DynamoDB AFT Request Table (AFT Management Account)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  Checking DynamoDB aft-request table"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔑 Assuming role in AFT Management Account ($AFT_ACCOUNT)..."
echo ""

# Assume role to AFT Management Account
CREDENTIALS=$(aws sts assume-role \
  --role-arn "arn:aws:iam::${AFT_ACCOUNT}:role/AWSControlTowerExecution" \
  --role-session-name "monitor-aft-accounts" \
  --output json 2>/dev/null)

if [ $? -eq 0 ]; then
  export AWS_ACCESS_KEY_ID=$(echo "$CREDENTIALS" | python3 -c "import sys, json; print(json.load(sys.stdin)['Credentials']['AccessKeyId'])")
  export AWS_SECRET_ACCESS_KEY=$(echo "$CREDENTIALS" | python3 -c "import sys, json; print(json.load(sys.stdin)['Credentials']['SecretAccessKey'])")
  export AWS_SESSION_TOKEN=$(echo "$CREDENTIALS" | python3 -c "import sys, json; print(json.load(sys.stdin)['Credentials']['SessionToken'])")
  
  echo "✅ Successfully assumed role in AFT Management Account"
  echo ""
  
  # Scan DynamoDB table for Student accounts
  echo "📊 Scanning aft-request table for Student accounts..."
  echo ""
  
  aws dynamodb scan \
    --table-name aft-request \
    --region "$AFT_REGION" \
    --filter-expression "contains(id, :student)" \
    --expression-attribute-values '{":student":{"S":"student"}}' \
    --query 'Items[].{AccountName:control_tower_parameters.M.AccountName.S, Email:control_tower_parameters.M.AccountEmail.S, Status:id.S}' \
    --output table 2>/dev/null || echo "⚠️  Unable to scan DynamoDB table"
  
  echo ""
  
  # Check 3: CodePipeline Status
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "3️⃣  Checking CodePipeline Status"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  PIPELINE_STATUS=$(aws codepipeline get-pipeline-state \
    --name ct-aft-account-request \
    --region "$AFT_REGION" \
    --query 'stageStates[0].latestExecution.status' \
    --output text 2>/dev/null)
  
  if [ -n "$PIPELINE_STATUS" ]; then
    case "$PIPELINE_STATUS" in
      "Succeeded")
        echo "✅ Pipeline Status: $PIPELINE_STATUS"
        ;;
      "InProgress")
        echo "🔄 Pipeline Status: $PIPELINE_STATUS (accounts being created...)"
        ;;
      "Failed")
        echo "❌ Pipeline Status: $PIPELINE_STATUS"
        echo ""
        echo "🔗 Check logs: https://ap-south-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/ct-aft-account-request/view"
        ;;
      *)
        echo "⚠️  Pipeline Status: $PIPELINE_STATUS"
        ;;
    esac
  else
    echo "⚠️  Unable to get pipeline status"
  fi
  
  # Unset temporary credentials
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN
else
  echo "⚠️  Unable to assume role. Check that:"
  echo "   1. Your AWS credentials are configured correctly"
  echo "   2. You have permission to assume AWSControlTowerExecution role"
  echo "   3. The role exists in account $AFT_ACCOUNT"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📌 NEXT STEPS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⏳ If accounts are not visible yet:"
echo "   - This is normal! Account creation takes 15-20 minutes"
echo "   - Run this script again in a few minutes"
echo "   - Check CodePipeline: https://ap-south-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/ct-aft-account-request/view"
echo ""
echo "✅ If accounts are visible:"
echo "   - They should appear in AWS Organizations shortly"
echo "   - Check: https://console.aws.amazon.com/organizations/v2/home/accounts"
echo "   - Search for 'Student' to filter accounts"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""


