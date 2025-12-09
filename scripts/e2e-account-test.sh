#!/bin/bash
# End-to-End Account Creation Test
# This script creates a new account and tracks it until ACTIVE

set -e

echo "🚀 AFT END-TO-END ACCOUNT CREATION TEST"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Generate unique identifiers
TIMESTAMP=$(date +%s)
EMAIL="ravish.snkhyn+e2etest${TIMESTAMP}@gmail.com"
ACCOUNT_NAME="E2ETest$(date +%m%d)"
MODULE_NAME="e2e_test_${TIMESTAMP}"

echo "📋 Test Account Details:"
echo "   Name: $ACCOUNT_NAME"
echo "   Email: $EMAIL"
echo "   OU: LearnMck"
echo ""

# Navigate to account request repo
cd /Users/ravish_sankhyan-guva/Devops-Sre-Aft/MCK-aft/learn-terraform-aft-account-request

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE 1: Creating Account Request"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Add account request
cat << MODULE >> terraform/main.tf

# E2E Test Account - Created $(date)
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
    "Purpose"     = "E2E Validation"
    "CreatedBy"   = "e2e-test-script"
  }

  change_management_parameters = {
    change_requested_by = "ravish_sankhyan-guva"
    change_reason       = "End-to-end AFT workflow validation"
  }

  custom_fields = {
    test_type = "e2e"
    timestamp = "$TIMESTAMP"
  }

  account_customizations_name = "sandbox"
}
MODULE

# Commit and push
git add terraform/main.tf
git commit -m "🧪 E2E Test: $ACCOUNT_NAME ($EMAIL)"
git pull --rebase origin main 2>/dev/null || true
git push origin main

echo "✅ Account request pushed to GitHub!"
echo ""

# Assume role for monitoring
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE 2: Monitoring Pipeline & Account Creation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

aws sts assume-role \
  --role-arn arn:aws:iam::809574937450:role/AWSControlTowerExecution \
  --role-session-name E2EMonitor \
  --profile ct-mgmt > /tmp/e2e-monitor.json

export AWS_ACCESS_KEY_ID=$(cat /tmp/e2e-monitor.json | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(cat /tmp/e2e-monitor.json | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(cat /tmp/e2e-monitor.json | jq -r '.Credentials.SessionToken')
export AWS_DEFAULT_REGION=ap-south-1

echo "Waiting 30 seconds for webhook trigger..."
sleep 30

# Complete monitoring loop
for i in {1..30}; do
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⏰ CHECK #$i/30 - $(date '+%H:%M:%S')"
  echo ""
  
  # 1. Pipeline Status
  PIPELINE_STATUS=$(aws codepipeline get-pipeline-state \
    --name ct-aft-account-request \
    --query 'stageStates[*].{Stage:stageName,Status:latestExecution.status}' \
    --output table 2>&1)
  echo "📊 Pipeline:"
  echo "$PIPELINE_STATUS" | head -8
  echo ""
  
  # 2. DynamoDB Check
  DDB_STATUS=$(aws dynamodb get-item \
    --table-name aft-request \
    --key "{\"id\": {\"S\": \"$EMAIL\"}}" \
    --query 'Item.control_tower_parameters.M.AccountName.S' \
    --output text 2>&1)
  
  if [ "$DDB_STATUS" != "None" ] && [ ! -z "$DDB_STATUS" ]; then
    echo "📋 DynamoDB: ✅ Request recorded ($DDB_STATUS)"
    
    # 3. Check Organizations
    ORG_CHECK=$(aws organizations list-accounts \
      --profile ct-mgmt \
      --query "Accounts[?Email=='$EMAIL']" 2>&1)
    
    if [ "$ORG_CHECK" != "[]" ] && [ ! -z "$ORG_CHECK" ]; then
      ACCOUNT_ID=$(echo "$ORG_CHECK" | jq -r '.[0].Id' 2>/dev/null)
      ACCOUNT_STATUS=$(echo "$ORG_CHECK" | jq -r '.[0].Status' 2>/dev/null)
      
      echo "🏢 Organizations: ✅ Account found!"
      echo "   ID: $ACCOUNT_ID"
      echo "   Status: $ACCOUNT_STATUS"
      
      if [ "$ACCOUNT_STATUS" = "ACTIVE" ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🎉🎉🎉 ACCOUNT CREATED SUCCESSFULLY! 🎉🎉🎉"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "✅ Account Name:   $ACCOUNT_NAME"
        echo "✅ Account ID:     $ACCOUNT_ID"
        echo "✅ Email:          $EMAIL"
        echo "✅ Status:         ACTIVE"
        echo "✅ Time Taken:     $((i * 2)) minutes"
        echo ""
        echo "🔗 View in Console:"
        echo "   https://console.aws.amazon.com/organizations/v2/home/accounts/$ACCOUNT_ID"
        echo ""
        echo "🎯 E2E Test: PASSED ✅"
        exit 0
      fi
    else
      echo "🏢 Organizations: ⏳ Not yet created"
    fi
  else
    echo "📋 DynamoDB: ⏳ Entry not yet created"
  fi
  
  if [ $i -lt 30 ]; then
    echo ""
    echo "⏳ Waiting 2 minutes before next check..."
    sleep 120
  fi
done

echo ""
echo "⏰ Timeout: Account not ACTIVE after 60 minutes"
echo "   Please check manually in AWS Console"

