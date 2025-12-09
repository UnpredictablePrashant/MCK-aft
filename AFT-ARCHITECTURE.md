# AFT Architecture Overview

## Account Structure

### Control Tower Management Account
- **Account ID:** 535355705679
- **Purpose:** AWS Control Tower setup, Organizations management
- **Credentials:** Used in GitHub secrets for workflow authentication
- **Region:** ap-south-1 (Mumbai)

### AFT Management Account
- **Account ID:** 809574937450
- **Purpose:** All AFT pipeline resources and automation
- **Region:** ap-south-1 (Mumbai)

**Key Resources in AFT Management Account:**
- CodePipeline: `ct-aft-account-request`
- CodePipeline: `ct-aft-account-provisioning-customizations`
- DynamoDB Table: `aft-request`
- DynamoDB Table: `aft-backend-v2-809574937450`
- Lambda Functions: All AFT orchestration functions
- Step Functions: Account provisioning workflow
- EventBridge: Triggers CodePipeline every 2 minutes

### Other Accounts
- **Log Archive Account:** 180574905686
- **Audit Account:** 002506421448
- **Created Accounts:** Provisioned in various OUs

---

## Regional Configuration

**Primary Region:** ap-south-1 (Mumbai)
**Secondary Region:** us-east-1 (for Terraform backend)

All AFT resources operate in **ap-south-1**.

---

## GitHub Workflows Authentication Flow

### Current Setup

```
GitHub Secrets (Control Tower Management Account 535355705679)
    ↓
    AWS_ACCESS_KEY_ID
    AWS_SECRET_ACCESS_KEY
    ↓
Workflow Assumes Role
    ↓
    arn:aws:iam::809574937450:role/AWSControlTowerExecution
    ↓
Temporary Credentials for AFT Management Account
    ↓
Access to AFT Resources in ap-south-1:
    - CodePipeline: ct-aft-account-request
    - DynamoDB: aft-request
    - Lambda functions
    - Step Functions
```

### Why This Works

1. **Control Tower Management account** has permissions to assume `AWSControlTowerExecution` role in member accounts
2. **AWSControlTowerExecution role** exists in AFT Management account with full permissions
3. **Workflows** use this role assumption to access AFT resources for monitoring
4. **All AWS CLI calls** use `--region ap-south-1` to access resources in Mumbai

---

## AFT Process Flow

### Account Creation

1. **User Action:** Submits workflow or pushes to Git
2. **GitHub Actions:** Creates Terraform module in `main.tf`
3. **Git Push:** Commits and pushes to `learn-terraform-aft-account-request` repo
4. **EventBridge:** Detects GitHub changes (polls every 2 minutes)
5. **CodePipeline:** Starts `ct-aft-account-request` pipeline in ap-south-1
6. **Terraform Apply:** Creates account request in DynamoDB
7. **Lambda Trigger:** Processes DynamoDB Stream event
8. **Step Functions:** Orchestrates account provisioning
9. **Control Tower:** Creates AWS account in specified OU
10. **Account Customizations:** Applies budgets, configs via second pipeline
11. **SSO User:** Creates user with access
12. **Account Status:** ACTIVE in AWS Organizations

**Duration:** Approximately 20 minutes end-to-end

---

## Key AFT Resources

### In AFT Management Account (809574937450) - ap-south-1

**CodePipeline:**
- `ct-aft-account-request` - Processes account requests from Git
- `ct-aft-account-provisioning-customizations` - Applies customizations

**DynamoDB:**
- `aft-request` - Stores all account requests
- `aft-backend-v2-809574937450` - Terraform state backend

**Lambda Functions:** (17 total)
- Account request processor
- Cleanup resources
- Customizations pipeline
- Various orchestration functions

**Step Functions:**
- `aft-account-provisioning-framework` - Main orchestration workflow

**EventBridge:**
- `aft-lambda-account-request-processor-scheduler` - Triggers every 2 minutes
- Polls GitHub for changes and triggers CodePipeline

**IAM Roles:**
- `AWSAFTService` - Main AFT service role
- `AWSControlTowerExecution` - Cross-account access role
- Various Lambda execution roles

---

## GitHub Repositories

### Main Repository
**URL:** https://github.com/UnpredictablePrashant/MCK-aft
**Purpose:** Parent repository with documentation and submodules

### Account Request Repository (Submodule)
**URL:** https://github.com/ravishmck/learn-terraform-aft-account-request
**Purpose:** Account request definitions
**Workflows:**
- `create-account.yml` - Single account creation
- `process-bulk-csv.yml` - Bulk CSV upload
- `close-account.yml` - Account decommissioning

### AFT Module Repository (Submodule)
**URL:** https://github.com/ravishmck/learn-terraform-aws-control-tower-aft
**Purpose:** AFT deployment configuration

### Account Customizations Repository (Submodule)
**URL:** https://github.com/ravishmck/learn-terraform-aft-account-customizations
**Purpose:** Post-provisioning customizations (budgets, SCPs)

---

## Organizational Units (OUs)

Available OUs for account placement:
- `LearnMck`
- `Sandbox`
- `Batch14`
- `Batch15`
- `AFT-Lab-Rajesh`
- `Security`
- `SuspendedAccount`

---

## Cost Controls

### Automatic AWS Budgets
- **Amount:** $200 per month per account
- **Alerts:** 80%, 90%, 100% (forecasted)
- **Alerts:** 100%, 110% (actual)
- **Applied:** Automatically to all new accounts

### Service Control Policies (SCPs)
- Blocks expensive services (SageMaker, Redshift, EMR)
- Restricts EC2 to t2/t3 micro/small instances only
- Limits EBS volumes to 100 GB
- Applied at OU level

---

## Monitoring and Verification

### Check Account Creation Status

**CodePipeline:**
```bash
aws codepipeline get-pipeline-state \
  --name ct-aft-account-request \
  --region ap-south-1
```

**DynamoDB:**
```bash
aws dynamodb scan \
  --table-name aft-request \
  --region ap-south-1
```

**AWS Organizations:**
```bash
aws organizations list-accounts \
  --query 'Accounts[?Name==`AccountName`]'
```

### URLs
- **CodePipeline:** https://ap-south-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/ct-aft-account-request/view
- **DynamoDB:** https://ap-south-1.console.aws.amazon.com/dynamodbv2/home?region=ap-south-1#table?name=aft-request
- **Organizations:** https://console.aws.amazon.com/organizations/v2/home/accounts

---

## Troubleshooting

### Workflow Monitoring Issues

**Problem:** Workflows can't find CodePipeline/DynamoDB

**Cause:** Using wrong account credentials

**Solution:** Workflows now automatically assume role to AFT Management account

### Pipeline Not Triggering

**Problem:** Account request committed but pipeline doesn't start

**Cause:** EventBridge polls every 2 minutes (not instant)

**Solution:** Wait 2-3 minutes after commit

### Account Creation Failures

**Check:**
1. CodePipeline execution logs in AFT Management account
2. Lambda function logs in CloudWatch (ap-south-1)
3. Step Functions execution in ap-south-1
4. DynamoDB table for request entry

---

## Production Status

✅ **Fully Operational**
- Single account creation via web form
- Bulk account creation via CSV upload
- Account closure/decommissioning
- Automatic cost controls ($200 budgets + SCPs)
- Cross-account role assumption for monitoring
- All resources in ap-south-1

**Limitations:**
- EventBridge polls every 2 minutes (not instant trigger)
- AWS account quota limits (request increase via Service Quotas)

---

## Security

### GitHub Secrets Required
- `AWS_ACCESS_KEY_ID` - Control Tower Management account
- `AWS_SECRET_ACCESS_KEY` - Control Tower Management account

**Note:** No session token in secrets - workflows generate temporary credentials via assume role

### IAM Permissions
- Control Tower Management account can assume `AWSControlTowerExecution` in all member accounts
- AFT service role has permissions to create accounts and apply policies
- Lambda functions have minimal required permissions

---

**Last Updated:** 2025-12-09
**Maintained By:** ravishmck
**Primary Contact:** ravish.snkhyn@gmail.com

