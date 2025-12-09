#!/bin/bash
# Run E2E Test After Closing WorkingAccount
# This script assumes you've already closed account 416418942202 via AWS Console

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 AFT END-TO-END ACCOUNT CREATION TEST"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check prerequisites
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install it first."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "❌ jq not found. Please install it first."
    exit 1
fi

export AWS_PROFILE=ct-mgmt
export AWS_DEFAULT_REGION=us-east-1

echo "Step 1: Verifying account slots available..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ACTIVE_COUNT=$(aws organizations list-accounts \
  --query 'length(Accounts[?Status==`ACTIVE`])' \
  --output text 2>/dev/null)

if [ -z "$ACTIVE_COUNT" ]; then
    echo "❌ Failed to check accounts. Your AWS credentials may have expired."
    echo ""
    echo "Please refresh your credentials in ~/.aws/credentials"
    echo "Then run this script again."
    exit 1
fi

echo "Active accounts: $ACTIVE_COUNT/10"
echo ""

if [ "$ACTIVE_COUNT" -ge 10 ]; then
    echo "⚠️  Still at account limit!"
    echo ""
    echo "Please close WorkingAccount first:"
    echo "1. Go to: https://us-east-1.console.aws.amazon.com/organizations/v2/home/accounts/416418942202"
    echo "2. Actions → Close account"
    echo "3. Type 'WorkingAccount' and confirm"
    echo "4. Run this script again"
    echo ""
    exit 1
fi

echo "✅ Space available! Proceeding with E2E test..."
echo ""

# Navigate to account request repo
REPO_DIR="/Users/ravish_sankhyan-guva/Devops-Sre-Aft/MCK-aft/learn-terraform-aft-account-request"
cd "$REPO_DIR"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Creating New Account Request"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Generate unique identifiers
TIMESTAMP=$(date +%s)
EMAIL="ravish.snkhyn+e2etest${TIMESTAMP}@gmail.com"
ACCOUNT_NAME="E2ETest$(date +%H%M)"
MODULE_NAME="e2e_test_${TIMESTAMP}"

echo "📋 New Account Details:"
echo "   Name: $ACCOUNT_NAME"
echo "   Email: $EMAIL"
echo "   Module: $MODULE_NAME"
echo ""

# Add account request to main.tf
cat << MODULE >> terraform/main.tf

# E2E Test - $(date)
module "$MODULE_NAME" {
  source = "./modules/aft-account-request"

  control_tower_parameters = {
    AccountEmail              = "$EMAIL"
    AccountName               = "$ACCOUNT_NAME"
    ManagedOrganizationalUnit = "LearnMck"
    SSOUserEmail              = "ravish.snkhyn@gmail.com"
    SSOUserFirstName          = "Ravish"
    SSOUserLastName           = "Sankhyan"
  }

  account_tags = {
    "Environment" = "Test"
    "ManagedBy"   = "AFT"
    "Purpose"     = "E2E-Validation"
    "TestDate"    = "$(date +%Y-%m-%d)"
  }

  change_management_parameters = {
    change_requested_by = "ravish_sankhyan-guva"
    change_reason       = "End-to-end AFT workflow test after Lambda VPC fix"
  }

  custom_fields = {
    test_type = "e2e_no_nat"
    timestamp = "$TIMESTAMP"
  }

  account_customizations_name = "sandbox"
}
MODULE

echo "✅ Account request added to main.tf"
echo ""

# Commit and push
echo "📤 Pushing to GitHub..."
git add terraform/main.tf
git commit -m "🧪 E2E Test: $ACCOUNT_NAME ($EMAIL)"
git pull --rebase origin main 2>/dev/null || true
git push origin main

echo ""
echo "✅ Request pushed! Pipeline will auto-trigger in ~30 seconds"
echo ""

# Assume role for monitoring
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Monitoring Account Creation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⏳ Waiting 30 seconds for pipeline trigger..."
sleep 30

aws sts assume-role \
  --role-arn arn:aws:iam::809574937450:role/AWSControlTowerExecution \
  --role-session-name E2ETest \
  --profile ct-mgmt > /tmp/e2e-monitor.json

export AWS_ACCESS_KEY_ID=$(cat /tmp/e2e-monitor.json | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(cat /tmp/e2e-monitor.json | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(cat /tmp/e2e-monitor.json | jq -r '.Credentials.SessionToken')
export AWS_DEFAULT_REGION=ap-south-1

echo "✅ Connected to AFT Management Account"
echo ""

# Monitoring loop
START_TIME=$(date +%s)
MAX_CHECKS=30

for i in $(seq 1 $MAX_CHECKS); do
  CURRENT_TIME=$(date +%s)
  ELAPSED=$((CURRENT_TIME - START_TIME))
  ELAPSED_MIN=$((ELAPSED / 60))
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⏰ CHECK #$i/$MAX_CHECKS - Elapsed: ${ELAPSED_MIN} minutes"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # 1. Pipeline Status
  PIPELINE_STATUS=$(aws codepipeline get-pipeline-state \
    --name ct-aft-account-request \
    --query 'stageStates[*].{Stage:stageName,Status:latestExecution.status}' \
    --output table 2>&1 | head -10)
  echo "📊 Pipeline:"
  echo "$PIPELINE_STATUS"
  echo ""
  
  # 2. DynamoDB Check
  DDB_STATUS=$(aws dynamodb get-item \
    --table-name aft-request \
    --key "{\"id\": {\"S\": \"$EMAIL\"}}" \
    --query 'Item.control_tower_parameters.M.AccountName.S' \
    --output text 2>&1)
  
  if [ "$DDB_STATUS" != "None" ] && [ ! -z "$DDB_STATUS" ]; then
    echo "📋 DynamoDB: ✅ Request recorded ($DDB_STATUS)"
    
    # 3. Organizations Check
    unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
    export AWS_PROFILE=ct-mgmt
    export AWS_DEFAULT_REGION=us-east-1
    
    ORG_CHECK=$(aws organizations list-accounts \
      --query "Accounts[?Email=='$EMAIL']" 2>&1)
    
    if [ "$ORG_CHECK" != "[]" ] && [ ! -z "$ORG_CHECK" ]; then
      ACCOUNT_ID=$(echo "$ORG_CHECK" | jq -r '.[0].Id' 2>/dev/null)
      ACCOUNT_STATUS=$(echo "$ORG_CHECK" | jq -r '.[0].Status' 2>/dev/null)
      
      echo "🏢 Organizations: ✅ Account found!"
      echo "   ID: $ACCOUNT_ID"
      echo "   Status: $ACCOUNT_STATUS"
      
      if [ "$ACCOUNT_STATUS" = "ACTIVE" ]; then
        TOTAL_TIME=$((ELAPSED_MIN))
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🎉🎉🎉 SUCCESS! ACCOUNT IS ACTIVE! 🎉🎉🎉"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "✅ Account Name:   $ACCOUNT_NAME"
        echo "✅ Account ID:     $ACCOUNT_ID"
        echo "✅ Email:          $EMAIL"
        echo "✅ Status:         ACTIVE"
        echo "✅ Time Taken:     ${TOTAL_TIME} minutes"
        echo ""
        echo "🔗 View in Console:"
        echo "   https://console.aws.amazon.com/organizations/v2/home/accounts/$ACCOUNT_ID"
        echo ""
        echo "🎯 E2E Test: PASSED ✅"
        echo ""
        exit 0
      fi
    else
      echo "🏢 Organizations: ⏳ Not yet created"
    fi
    
    # Re-assume AFT role for next check
    export AWS_ACCESS_KEY_ID=$(cat /tmp/e2e-monitor.json | jq -r '.Credentials.AccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(cat /tmp/e2e-monitor.json | jq -r '.Credentials.SecretAccessKey')
    export AWS_SESSION_TOKEN=$(cat /tmp/e2e-monitor.json | jq -r '.Credentials.SessionToken')
    export AWS_DEFAULT_REGION=ap-south-1
  else
    echo "📋 DynamoDB: ⏳ Entry not yet created"
  fi
  
  if [ $i -lt $MAX_CHECKS ]; then
    echo ""
    echo "⏳ Waiting 2 minutes before next check..."
    sleep 120
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⏰ Timeout: Account not ACTIVE after 60 minutes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Please check manually:"
echo "  DynamoDB: https://console.aws.amazon.com/dynamodbv2/home?region=ap-south-1#table?name=aft-request"
echo "  Service Catalog: https://console.aws.amazon.com/servicecatalog/home?region=ap-south-1#/products"
echo "  Organizations: https://console.aws.amazon.com/organizations/v2/home/accounts"
echo ""

