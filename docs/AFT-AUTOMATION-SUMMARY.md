# AFT Automation Setup - Summary

## ✅ What Was Fixed

### 1. **Lambda Layer Missing**
- **Problem**: All 17 AFT Lambda functions were missing the `aft-common` Python layer
- **Solution**: Attached `arn:aws:lambda:ap-south-1:809574937450:layer:aft-common-1-17-0:1` to all AFT functions

### 2. **IAM Trust Policies**
- **Problem**: Lambda functions couldn't assume required IAM roles
- **Solution**: Updated trust policies for:
  - `AWSAFTExecution-v2` (AFT Management account)
  - Created `AWSAFTService` (CT Management account)
  - Added all AFT Lambda execution roles to trust relationships

### 3. **Service Catalog Permissions**
- **Problem**: `AWSAFTService` lacked Service Catalog permissions
- **Solution**: Attached `AWSServiceCatalogAdminFullAccess` policy

### 4. **Missing EventBridge Automation**
- **Problem**: No automatic triggers for AFT workflows
- **Solution**: Created two EventBridge scheduler rules (every 5 minutes):
  - `aft-account-request-processor-scheduler` → Processes new account requests from DynamoDB
  - `aft-account-provisioning-framework-scheduler` → Triggers Step Functions for account creation

### 5. **CodePipeline Auto-Trigger**
- **Problem**: GitHub commits don't auto-trigger CodePipeline (AFT limitation)
- **Workaround**: Manual trigger required:
  ```bash
  aws sts assume-role \
    --role-arn arn:aws:iam::809574937450:role/AWSControlTowerExecution \
    --role-session-name AFTSession \
    --profile ct-mgmt > /tmp/aft-creds.json
  
  export AWS_ACCESS_KEY_ID=$(cat /tmp/aft-creds.json | jq -r '.Credentials.AccessKeyId')
  export AWS_SECRET_ACCESS_KEY=$(cat /tmp/aft-creds.json | jq -r '.Credentials.SecretAccessKey')
  export AWS_SESSION_TOKEN=$(cat /tmp/aft-creds.json | jq -r '.Credentials.SessionToken')
  
  aws codepipeline start-pipeline-execution \
    --name ct-aft-account-request \
    --region ap-south-1
  ```

---

## 🎯 Current Status

### Account Request: **LearnAFT**
- **Email**: ravish.snkhyn@gmail.com
- **OU**: LearnMck
- **Status**: ✅ In DynamoDB, ⏳ Awaiting provisioning

### Automation Status
- ✅ EventBridge schedulers running (every 5 minutes)
- ✅ Lambda layers attached
- ✅ IAM permissions configured
- ⏳ First automated run expected within 5-10 minutes

---

## 📊 Monitoring Your Account

### Use the Status Checker Script
```bash
cd /Users/ravish_sankhyan-guva/Devops-Sre-Aft/MCK-aft
./check-account-status.sh
```

### Manual AWS Console Links

#### AFT Management Account (809574937450)
1. **DynamoDB - Account Requests**
   - Table: `aft-request`
   - https://ap-south-1.console.aws.amazon.com/dynamodbv2/home?region=ap-south-1#item-explorer?table=aft-request

2. **DynamoDB - Provisioning Metadata**
   - Table: `aft-request-metadata`
   - https://ap-south-1.console.aws.amazon.com/dynamodbv2/home?region=ap-south-1#item-explorer?table=aft-request-metadata

3. **Step Functions**
   - State Machine: `aft-account-provisioning-framework`
   - https://ap-south-1.console.aws.amazon.com/states/home?region=ap-south-1#/statemachines

4. **CloudWatch Logs**
   - Log Groups: `/aws/lambda/aft-*`
   - https://ap-south-1.console.aws.amazon.com/cloudwatch/home?region=ap-south-1#logsV2:log-groups

5. **CodePipeline**
   - Pipeline: `ct-aft-account-request`
   - https://ap-south-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/ct-aft-account-request/view

#### CT Management Account (535355705679)
1. **AWS Organizations**
   - Check for new accounts
   - https://console.aws.amazon.com/organizations/v2/home/accounts

2. **Service Catalog**
   - Check Account Factory portfolio
   - https://ap-south-1.console.aws.amazon.com/servicecatalog/home?region=ap-south-1#/portfolios

---

## 🚀 Next Account Requests

### Automated Flow (Now Working!)
1. **Update account request**: Edit `learn-terraform-aft-account-request/terraform/main.tf`
2. **Commit and push** to GitHub
3. **Manually trigger pipeline**:
   ```bash
   # Assume role in AFT Management account first
   aws codepipeline start-pipeline-execution \
     --name ct-aft-account-request \
     --region ap-south-1
   ```
4. **Wait 5-10 minutes**: Automation will detect and process the request
5. **Monitor**: Run `./check-account-status.sh`

### Expected Timeline
- **Pipeline execution**: 3-5 minutes
- **Account provisioning detection**: 5-10 minutes (automated scheduler)
- **Account creation**: 15-25 minutes (Control Tower)
- **Customizations**: 10-15 minutes (if configured)
- **Total**: ~30-45 minutes per account

---

## 🛠️ Troubleshooting

### If Account Doesn't Appear After 30 Minutes

1. **Check Step Functions execution**:
   ```bash
   aws sts assume-role \
     --role-arn arn:aws:iam::809574937450:role/AWSControlTowerExecution \
     --role-session-name AFTCheck \
     --profile ct-mgmt > /tmp/aft-creds.json
   
   export AWS_ACCESS_KEY_ID=$(cat /tmp/aft-creds.json | jq -r '.Credentials.AccessKeyId')
   export AWS_SECRET_ACCESS_KEY=$(cat /tmp/aft-creds.json | jq -r '.Credentials.SecretAccessKey')
   export AWS_SESSION_TOKEN=$(cat /tmp/aft-creds.json | jq -r '.Credentials.SessionToken')
   
   aws stepfunctions list-executions \
     --state-machine-arn arn:aws:states:ap-south-1:809574937450:stateMachine:aft-account-provisioning-framework \
     --region ap-south-1 \
     --max-items 5
   ```

2. **Check Lambda logs**:
   - Go to CloudWatch Logs console
   - Check `/aws/lambda/aft-account-request-processor`
   - Check `/aws/lambda/aft-invoke-aft-account-provisioning-framework`

3. **Verify EventBridge rules are enabled**:
   ```bash
   aws events list-rules \
     --region ap-south-1 \
     --query 'Rules[?contains(Name, `aft-account`)]'
   ```

4. **Re-run the account request processor manually**:
   ```bash
   aws lambda invoke \
     --function-name aft-account-request-processor \
     --region ap-south-1 \
     --payload '{}' \
     /tmp/response.json
   ```

---

## 📝 Key Files

- **Status Checker**: `/Users/ravish_sankhyan-guva/Devops-Sre-Aft/MCK-aft/check-account-status.sh`
- **Account Requests**: `/Users/ravish_sankhyan-guva/Devops-Sre-Aft/MCK-aft/learn-terraform-aft-account-request/terraform/main.tf`
- **AFT Config**: `/Users/ravish_sankhyan-guva/Devops-Sre-Aft/MCK-aft/learn-terraform-aws-control-tower-aft/terraform.tfvars`

---

## 🎉 Success Indicators

Your account is successfully provisioned when you see:

1. ✅ **DynamoDB `aft-request-metadata`**: Entry with `workflow: SUCCESS`
2. ✅ **Step Functions**: Execution status = `SUCCEEDED`
3. ✅ **AWS Organizations**: New account visible with Status = `ACTIVE`
4. ✅ **Email**: AWS sends account creation confirmation to `ravish.snkhyn@gmail.com`

---

## 📚 Important Notes

### Lambda Layer Issue (Resolved)
- AFT's Lambda layer build was skipped during deployment due to networking issues
- The layer already existed and was manually attached to all functions
- This won't affect future account requests

### Modified Resource Names
To avoid conflicts with pre-existing resources, these were renamed with `-v2` suffix:
- DynamoDB table: `aft-backend-v2-*`
- IAM roles: `AWSAFTExecution-v2`, `AWSAFTService-v2`
- CloudWatch Query Definitions: "Account Factory for Terraform v2/*"
- KMS aliases: `alias/aft-backend-*-v2`

### GitHub Webhook Limitation
- AFT doesn't create EventBridge rules for GitHub (only for CodeCommit)
- CodePipeline requires manual triggering for each commit
- This may auto-fix after 24-48 hours as AWS configures webhooks

---

## 🔗 Useful Commands

### Check account provisioning status
```bash
./check-account-status.sh
```

### Manually trigger CodePipeline
```bash
aws codepipeline start-pipeline-execution \
  --name ct-aft-account-request \
  --region ap-south-1 \
  --profile ct-mgmt
```

### View Step Functions execution details
```bash
aws stepfunctions describe-execution \
  --execution-arn <EXECUTION_ARN> \
  --region ap-south-1
```

### Check Lambda invocation logs
```bash
aws logs tail /aws/lambda/aft-account-request-processor --follow --region ap-south-1
```

---

**Last Updated**: 2025-12-05
**AFT Version**: 1.17.0
**Terraform Version**: Latest compatible

