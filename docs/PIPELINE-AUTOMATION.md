# AFT Pipeline Automation - Complete Guide

## 🎯 Why Was Manual Triggering Required?

### The AFT Limitation

AFT's Terraform code **only** creates automatic triggers for AWS CodeCommit, not for GitHub/Bitbucket:

```terraform
# For CodeCommit - Auto-triggers ✅
resource "aws_cloudwatch_event_rule" "account_request" {
  count = local.vcs.is_codecommit ? 1 : 0  # Only for CodeCommit!
  # ... EventBridge rule that triggers on git push
}

# For GitHub - No auto-trigger ❌
resource "aws_codepipeline" "codeconnections_account_request" {
  count = local.vcs.is_codecommit ? 0 : 1  # GitHub/Bitbucket
  configuration = {
    DetectChanges = true  # Relies on webhooks (unreliable)
  }
  # NO EventBridge rule created!
}
```

**Result:** GitHub pushes don't trigger the pipeline automatically.

---

## ✅ Solution: Custom EventBridge Rule

I created an EventBridge rule that monitors CodeConnections for GitHub push events:

### EventBridge Rule Configuration

```json
{
  "source": ["aws.codeconnections"],
  "detail-type": ["CodeConnections Source Action State Change"],
  "detail": {
    "state": ["SUCCEEDED"],
    "event": ["referenceUpdated"],
    "referenceType": ["branch"],
    "referenceName": ["main"],
    "repositoryName": ["ravishmck/learn-terraform-aft-account-request"]
  }
}
```

**What this does:**
- Monitors: AWS CodeConnections service
- Detects: Push to `main` branch
- Repository: `ravishmck/learn-terraform-aft-account-request`
- Action: Triggers CodePipeline `ct-aft-account-request`

### Components Created

| Resource | ARN |
|----------|-----|
| **EventBridge Rule** | `arn:aws:events:ap-south-1:809574937450:rule/aft-github-account-request-trigger` |
| **IAM Role** | `arn:aws:iam::809574937450:role/aft-eventbridge-pipeline-trigger` |
| **Target** | `ct-aft-account-request` CodePipeline |

---

## 🔄 Complete Automation Flow

### Before (Manual)

```
1. Edit learn-terraform-aft-account-request/terraform/main.tf
2. Commit and push to GitHub
3. ❌ Nothing happens
4. Manual: aws codepipeline start-pipeline-execution
5. CodePipeline runs
```

### After (Automated)

```
1. Edit learn-terraform-aft-account-request/terraform/main.tf
2. Commit and push to GitHub
3. ✅ CodeConnections detects push (~30 sec)
4. ✅ EventBridge triggers pipeline automatically
5. ✅ CodePipeline runs without manual intervention
6. ✅ Account request → DynamoDB
7. ✅ EventBridge scheduler (5 min) → Lambda processor
8. ✅ Lambda → SQS queue
9. ✅ SQS → Step Functions
10. ✅ Account provisioned!
```

---

## ⚙️ EventBridge Schedulers

Two additional schedulers run every 5 minutes:

### 1. Account Request Processor

**Rule:** `aft-account-request-processor-scheduler`
- **Target:** `aft-account-request-processor` Lambda
- **Purpose:** Checks DynamoDB for new requests and processes them
- **Frequency:** Every 5 minutes

### 2. Provisioning Framework Trigger

**Rule:** `aft-account-provisioning-framework-scheduler`
- **Target:** `aft-invoke-aft-account-provisioning-framework` Lambda
- **Purpose:** Triggers Step Functions for account creation
- **Frequency:** Every 5 minutes

---

## 📊 Monitoring Automation

### Check If Automation Is Working

```bash
# Check EventBridge invocations
aws cloudwatch get-metric-statistics \
  --namespace AWS/Events \
  --metric-name TriggeredRules \
  --dimensions Name=RuleName,Value=aft-github-account-request-trigger \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --region ap-south-1

# Check Lambda invocations
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=aft-account-request-processor \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --region ap-south-1
```

### View EventBridge Rules

```bash
aws events list-rules \
  --region ap-south-1 \
  --query 'Rules[?contains(Name, `aft`)].[Name, State, ScheduleExpression]'
```

---

## 🐛 Troubleshooting

### Pipeline Still Not Triggering Automatically?

**Check EventBridge rule status:**
```bash
aws events describe-rule \
  --name aft-github-account-request-trigger \
  --region ap-south-1
```

**Verify targets are configured:**
```bash
aws events list-targets-by-rule \
  --rule aft-github-account-request-trigger \
  --region ap-south-1
```

**Check IAM role permissions:**
```bash
aws iam get-role-policy \
  --role-name aft-eventbridge-pipeline-trigger \
  --policy-name StartPipelineExecution
```

### Accounts Not Being Created?

**Check Lambda logs:**
```bash
aws logs tail /aws/lambda/aft-account-request-action-trigger --since 1h --region ap-south-1
aws logs tail /aws/lambda/aft-account-request-processor --since 1h --region ap-south-1
```

**Check SQS queue:**
```bash
aws sqs get-queue-attributes \
  --queue-url https://sqs.ap-south-1.amazonaws.com/809574937450/aft-account-request-v2.fifo \
  --attribute-names All \
  --region ap-south-1
```

**Check Step Functions:**
```bash
STATE_MACHINE_ARN=$(aws stepfunctions list-state-machines \
  --region ap-south-1 \
  --query 'stateMachines[?contains(name, `aft-account-provisioning-framework`)].stateMachineArn' \
  --output text)

aws stepfunctions list-executions \
  --state-machine-arn "$STATE_MACHINE_ARN" \
  --region ap-south-1
```

---

## 🔧 Manual Overrides

If automation fails, you can manually trigger:

### Trigger CodePipeline
```bash
aws codepipeline start-pipeline-execution \
  --name ct-aft-account-request \
  --region ap-south-1
```

### Trigger Account Processor
```bash
aws lambda invoke \
  --function-name aft-account-request-processor \
  --region ap-south-1 \
  --payload '{}' \
  /tmp/response.json
```

### Trigger Provisioning Framework
```bash
aws lambda invoke \
  --function-name aft-invoke-aft-account-provisioning-framework \
  --region ap-south-1 \
  --payload '{"detail-type": "Scheduled Event", "source": "aws.events", "detail": {}}' \
  /tmp/response.json
```

---

## 📚 Key Learnings

### Why AFT Doesn't Support GitHub Auto-Triggers

1. **Historical Design**: AFT was originally built for AWS CodeCommit
2. **CodeConnections**: Newer service, webhook creation is async
3. **Reliability**: EventBridge rules are more reliable than webhooks
4. **AWS Limitation**: CodeConnections webhooks can take 24-48 hours to activate

### Our Custom Solution

- ✅ **EventBridge rule** for immediate push detection
- ✅ **IAM role** with minimal permissions for pipeline execution
- ✅ **Scheduled Lambda triggers** for processing (every 5 min)
- ✅ **Cross-account IAM roles** for AFT operations

---

## 🚀 Testing the Automation

### Test 1: Push Detection

1. Edit `learn-terraform-aft-account-request/terraform/main.tf`
2. Commit and push
3. Wait ~30-60 seconds
4. Check: https://ap-south-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/ct-aft-account-request/view
5. Pipeline should be running automatically!

### Test 2: Account Creation

1. Add new account module to `main.tf`
2. Push to GitHub (pipeline auto-triggers)
3. Wait 5-10 minutes
4. Run: `./scripts/check-account-status.sh`
5. Account should appear in DynamoDB metadata
6. Check Organizations for new account

---

## 📊 Expected Timeline

| Time | Event |
|------|-------|
| 0:00 | Push to GitHub |
| 0:30 | CodePipeline triggered (EventBridge) |
| 3:30 | Terraform apply complete |
| 3:30 | Account request → DynamoDB |
| 3:30 | DynamoDB Stream → Lambda |
| 3:30 | Lambda → SQS queue |
| 8:30 | EventBridge scheduler → Account processor |
| 8:30 | SQS → Step Functions |
| 10:00 | Step Functions starts provisioning |
| 45:00 | **Account fully provisioned** ✅ |

**Total Time:** ~45-50 minutes from push to ready account

---

## 🔗 Resources

### EventBridge Rules (AFT Management - 809574937450)
- `aft-github-account-request-trigger` - CodePipeline auto-trigger
- `aft-account-request-processor-scheduler` - Process requests (5 min)
- `aft-account-provisioning-framework-scheduler` - Trigger provisioning (5 min)

### IAM Roles

**AFT Management Account (809574937450):**
- `AWSAFTExecution-v2` - Execution role
- `AWSAFTService-v2` - Service role
- `aft-eventbridge-pipeline-trigger` - EventBridge → CodePipeline

**CT Management Account (535355705679):**
- `AWSAFTExecution-v2` - Cross-account execution
- `AWSAFTService-v2` - Cross-account service
- `AWSAFTService` - Legacy service role

### Lambda Functions
- `aft-account-request-processor` - Checks DynamoDB and SQS
- `aft-account-request-action-trigger` - DynamoDB Stream → SQS
- `aft-invoke-aft-account-provisioning-framework` - Starts Step Functions

---

## 💡 Pro Tips

1. **First Push**: May take longer (60-90 sec) for EventBridge to detect
2. **Subsequent Pushes**: Should trigger within 30 seconds
3. **Webhook Backup**: AWS may still create webhooks after 24-48 hours
4. **Monitoring**: Always check CloudWatch Logs if something seems stuck
5. **IAM Propagation**: Allow 10-15 seconds after IAM changes

---

**Last Updated:** 2025-12-08  
**Status:** ✅ Fully Automated  
**Account:** AFT Management (809574937450)

