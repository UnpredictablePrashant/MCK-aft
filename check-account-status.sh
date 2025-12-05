#!/bin/bash
# AFT Account Provisioning Status Checker
# Checks status across AFT Management (809574937450) and CT Management (535355705679) accounts

echo "🔍 AFT Account Provisioning Status Check"
echo "=========================================="
echo ""

# Assume role in AFT Management account
echo "Assuming role in AFT Management account..."
ASSUMED_ROLE=$(aws sts assume-role \
  --role-arn arn:aws:iam::809574937450:role/AWSControlTowerExecution \
  --role-session-name AFTStatusCheck \
  --profile ct-mgmt \
  --query 'Credentials')

export AWS_ACCESS_KEY_ID=$(echo $ASSUMED_ROLE | jq -r '.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $ASSUMED_ROLE | jq -r '.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $ASSUMED_ROLE | jq -r '.SessionToken')
export AWS_DEFAULT_REGION="ap-south-1"

echo "✅ Connected to AFT Management account"
echo ""

# Check DynamoDB for account request
echo "1️⃣ Account Request in DynamoDB:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
aws dynamodb get-item \
  --table-name aft-request \
  --region ap-south-1 \
  --key '{"id": {"S": "ravish.snkhyn@gmail.com"}}' \
  --query 'Item.{Email: id.S, AccountName: control_tower_parameters.M.AccountName.S, OU: control_tower_parameters.M.ManagedOrganizationalUnit.S}' \
  --output table

echo ""

# Check DynamoDB metadata
echo "2️⃣ Account Provisioning Metadata:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
METADATA=$(aws dynamodb scan \
  --table-name aft-request-metadata \
  --region ap-south-1 \
  --query 'Items[?id.S==`ravish.snkhyn@gmail.com`].[id.S, account_name.S, workflow.S, vcs_status.S]' \
  --output table)

if [ -z "$METADATA" ] || [ "$METADATA" = "" ]; then
  echo "⏳ No metadata yet - provisioning hasn't started"
else
  echo "$METADATA"
fi

echo ""

# Check Step Functions
echo "3️⃣ Step Functions Execution Status:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
STATE_MACHINE_ARN=$(aws stepfunctions list-state-machines \
  --region ap-south-1 \
  --query 'stateMachines[?contains(name, `aft-account-provisioning-framework`)].stateMachineArn' \
  --output text)

EXECUTIONS=$(aws stepfunctions list-executions \
  --state-machine-arn "$STATE_MACHINE_ARN" \
  --region ap-south-1 \
  --max-items 3 \
  --query 'executions[*].[name, status, startDate]' \
  --output table)

if [ -z "$EXECUTIONS" ] || [ "$EXECUTIONS" = "" ]; then
  echo "⏳ No Step Functions executions yet"
else
  echo "$EXECUTIONS"
fi

echo ""

# Check AWS Organizations for new account
echo "4️⃣ AWS Organizations - LearnAFT Account:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
export AWS_PROFILE=ct-mgmt
export AWS_DEFAULT_REGION=ap-south-1

ACCOUNT=$(aws organizations list-accounts \
  --query 'Accounts[?contains(Email, `ravish.snkhyn@gmail.com`)].[Name, Email, Status, Id]' \
  --output table)

if [ -z "$ACCOUNT" ] || [ "$ACCOUNT" = "" ]; then
  echo "⏳ Account not created yet"
else
  echo "$ACCOUNT"
  echo ""
  echo "✅ ACCOUNT FOUND!"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Next Steps:"
echo ""
echo "If the account hasn't been created yet, you can:"
echo "  1. Wait 5-10 minutes and run this script again"
echo "  2. Check CodePipeline manually:"
echo "     https://ap-south-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/ct-aft-account-request/view"
echo "  3. View logs in CloudWatch:"
echo "     https://ap-south-1.console.aws.amazon.com/cloudwatch/home?region=ap-south-1#logsV2:log-groups"
echo ""

