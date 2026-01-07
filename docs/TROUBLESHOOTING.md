# 🔧 Troubleshooting Guide

This guide helps diagnose and fix common issues with AFT account provisioning.

---

## 🚨 Quick Diagnostics

### Check Pipeline Status

```bash
# See if CodePipeline is running
aws codepipeline get-pipeline-state \
  --name ct-aft-account-request \
  --region ap-south-1 \
  --query 'stageStates[*].[stageName,latestExecution.status]' \
  --output table
```

### Check DynamoDB Request

```bash
# See if account request exists
aws dynamodb scan \
  --table-name aft-request \
  --region ap-south-1 \
  --query 'Items[*].[id.S,control_tower_parameters.M.AccountName.S]' \
  --output table
```

### Check Account Status

```bash
# See if account is ACTIVE
aws organizations list-accounts \
  --query "Accounts[?Name=='YourAccountName'].[Name,Status,Id]" \
  --output table
```

---

## 📋 Common Issues

### Issue 1: Account Not Created After 30 Minutes

**Symptoms:**
- Workflow completed successfully
- Account not appearing in AWS Organizations
- No errors visible

**Diagnosis:**

1. **Check CodePipeline:**
```bash
aws codepipeline get-pipeline-state \
  --name ct-aft-account-request \
  --region ap-south-1
```

2. **Check DynamoDB:**
```bash
aws dynamodb scan \
  --table-name aft-request \
  --region ap-south-1 \
  --filter-expression "contains(id, :email)" \
  --expression-attribute-values '{":email":{"S":"your-email@example.com"}}'
```

3. **Check Step Functions:**
```bash
aws stepfunctions list-executions \
  --state-machine-arn arn:aws:states:ap-south-1:809574937450:stateMachine:aft-account-provisioning-framework \
  --max-items 5
```

**Solutions:**

- ⏰ **Wait:** EventBridge polls every 2 minutes; allow 5-10 min
- 🔄 **Re-trigger:** Make a small commit to the account-request repo
- 📋 **Check logs:** Look at CodeBuild logs for errors

---

### Issue 2: Email Already Used Error

**Symptoms:**
```
Email address is already associated with another AWS account
```

**Diagnosis:**
```bash
aws organizations list-accounts \
  --query "Accounts[?Email=='the-email@example.com']"
```

**Solutions:**

1. **Use a different email:**
   ```
   # Use Gmail + trick
   user+account1@gmail.com
   user+account2@gmail.com
   ```

2. **Close the old account** if no longer needed
   - See [How to Close Accounts](./HOW-TO-CLOSE-ACCOUNTS.md)

---

### Issue 3: Account Limit Reached

**Symptoms:**
```
AWS Control Tower cannot create an account because you have reached the limit
```

**Diagnosis:**
```bash
# Count current accounts
aws organizations list-accounts --query 'length(Accounts)'
```

**Solutions:**

1. **Close unused accounts:**
   - Move to SuspendedAccount OU first
   - Then close via AWS Organizations

2. **Request quota increase:**
   - See [Service Quota Increase Guide](./SERVICE-QUOTA-INCREASE.md)

---

### Issue 4: Pipeline Stuck in "InProgress"

**Symptoms:**
- CodePipeline shows stage as "InProgress" for >30 minutes
- No progress visible

**Diagnosis:**
```bash
# Check current execution
aws codepipeline get-pipeline-execution \
  --pipeline-name ct-aft-account-request \
  --pipeline-execution-id EXECUTION_ID \
  --region ap-south-1
```

**Solutions:**

1. **Stop and retry:**
```bash
aws codepipeline stop-pipeline-execution \
  --pipeline-name ct-aft-account-request \
  --pipeline-execution-id EXECUTION_ID \
  --reason "Timeout - retrying" \
  --region ap-south-1
```

2. **Check CodeBuild logs:**
```
https://ap-south-1.console.aws.amazon.com/codesuite/codebuild/projects
```

---

### Issue 5: Terraform State Lock Error

**Symptoms:**
```
Error acquiring the state lock
ConditionalCheckFailedException
```

**Diagnosis:**
```bash
# Check if lock exists
aws dynamodb scan \
  --table-name aft-backend-v2-809574937450 \
  --filter-expression "attribute_exists(LockID)" \
  --region ap-south-1
```

**Solutions:**

1. **Wait 10-15 minutes** - lock may release automatically

2. **Force unlock (use with caution!):**
```bash
# Get the lock ID from the error message
terraform force-unlock LOCK_ID
```

3. **Delete stale lock:**
```bash
aws dynamodb delete-item \
  --table-name aft-backend-v2-809574937450 \
  --key '{"LockID": {"S": "THE_LOCK_ID"}}' \
  --region ap-south-1
```

---

### Issue 6: GitHub Workflow "Push Failed"

**Symptoms:**
```
error: failed to push some refs
Updates were rejected because the remote contains work
```

**Cause:** Multiple workflows running simultaneously

**Solutions:**

1. **Workflow auto-retries** - wait for it

2. **Manual re-run:**
   - Go to GitHub Actions
   - Click "Re-run failed jobs"

3. **Pull and push manually:**
```bash
cd learn-terraform-aft-account-request
git pull --rebase origin main
git push
```

---

### Issue 7: Invalid JSON Error

**Symptoms:**
```
Error: Invalid JSON in account request
```

**Diagnosis:**
- Check the generated `main.tf` for syntax errors

**Solutions:**

1. **Validate JSON online:** https://jsonlint.com/

2. **Check for special characters** in account names/emails

3. **Use CSV workflow** instead of JSON for bulk creation

---

### Issue 8: Access Denied for Cross-Account Access

**Symptoms:**
```
AccessDenied: User is not authorized to perform sts:AssumeRole
```

**Diagnosis:**
```bash
# Check if role exists
aws iam get-role \
  --role-name AWSControlTowerExecution \
  --profile ct-mgmt
```

**Solutions:**

1. **Verify trust policy** includes your account

2. **Check role ARN** is correct:
```
arn:aws:iam::809574937450:role/AWSControlTowerExecution
```

3. **Ensure source account** has sts:AssumeRole permission

---

### Issue 9: Budget Not Created

**Symptoms:**
- Account created successfully
- No budget alerts configured

**Diagnosis:**
```bash
aws budgets describe-budgets \
  --account-id ACCOUNT_ID \
  --query "Budgets[?BudgetName=='monthly-budget-200-usd']"
```

**Solutions:**

1. **Check customizations pipeline:**
```bash
aws codepipeline get-pipeline-state \
  --name ct-aft-account-provisioning-customizations \
  --region ap-south-1
```

2. **Manually trigger customizations:**
```bash
aws codepipeline start-pipeline-execution \
  --name ct-aft-account-provisioning-customizations \
  --region ap-south-1
```

---

### Issue 10: SCP Blocking Needed Actions

**Symptoms:**
```
AccessDeniedException: User is not authorized to perform [action] 
with an explicit deny in a service control policy
```

**Diagnosis:**
```bash
# Check SCPs on the account/OU
aws organizations list-policies-for-target \
  --target-id ou-hn55-xxxxx \
  --filter SERVICE_CONTROL_POLICY
```

**Solutions:**

1. **Detach SCP temporarily:**
```bash
aws organizations detach-policy \
  --policy-id p-xxxxxxxx \
  --target-id ou-hn55-xxxxx \
  --profile ct-mgmt
```

2. **Modify SCP** to allow the action:
   - Edit `policies/scp/deny-expensive-services.json`
   - Update the policy

3. **Move account** to OU without SCP

---

## 🔍 Where to Find Logs

### CodePipeline Logs
```
https://ap-south-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/ct-aft-account-request/view
```

### CodeBuild Logs
```
https://ap-south-1.console.aws.amazon.com/codesuite/codebuild/projects
```

### Lambda Logs
```bash
# Account Request Processor
aws logs tail /aws/lambda/aft-account-request-processor \
  --since 30m \
  --region ap-south-1
```

### Step Functions
```
https://ap-south-1.console.aws.amazon.com/states/home?region=ap-south-1#/statemachines
```

### CloudWatch Logs

```bash
# List all AFT log groups
aws logs describe-log-groups \
  --log-group-name-prefix /aws/lambda/aft \
  --region ap-south-1 \
  --query 'logGroups[*].logGroupName'
```

---

## 🛠️ Useful Scripts

### Check Account Status Script

```bash
bash scripts/check-account-status.sh
```

This script:
1. Checks DynamoDB for account request
2. Shows Step Functions execution status
3. Verifies account in AWS Organizations

### End-to-End Test Script

```bash
bash scripts/e2e-account-test.sh
```

This script:
1. Creates a test account request
2. Monitors pipeline progress
3. Verifies account creation
4. Cleans up test account

---

## 📞 Escalation Path

If none of the above solutions work:

1. **Check AWS Service Health:**
   ```
   https://health.aws.amazon.com/health/status
   ```

2. **Review CloudWatch Logs** for specific error messages

3. **Contact AWS Support** if:
   - Control Tower issues
   - Service Catalog failures
   - Quota increase requests

---

## 📚 Related Documentation

- [How to Create Accounts](./HOW-TO-CREATE-ACCOUNTS.md)
- [How to Close Accounts](./HOW-TO-CLOSE-ACCOUNTS.md)
- [AFT Architecture](./AFT-ARCHITECTURE-NO-NAT.md)
- [Cost Control Setup](./COST-CONTROL-SETUP.md)
- [Service Quota Increase](./SERVICE-QUOTA-INCREASE.md)

---

**Last Updated:** January 2026  
**AFT Version:** 1.17.0

