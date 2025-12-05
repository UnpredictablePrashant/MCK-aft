# GitHub Actions for AFT - Quick Start Guide

## 🚀 One-Time Setup (5 minutes)

### Step 1: Add GitHub Secrets

1. Go to your repository: https://github.com/ravishmck/learn-terraform-aft-account-request
2. Navigate to: **Settings → Secrets and variables → Actions**
3. Click **"New repository secret"**
4. Add these two secrets:

| Secret Name | Value |
|-------------|-------|
| `AFT_AWS_ACCESS_KEY_ID` | Your AWS Access Key ID from `~/.aws/credentials` |
| `AFT_AWS_SECRET_ACCESS_KEY` | Your AWS Secret Access Key from `~/.aws/credentials` |

> ⚠️ **Security Note**: These are your `ct-mgmt` profile credentials. Consider creating a dedicated IAM user for GitHub Actions in production.

### Step 2: Enable Workflow Permissions

1. In your repository: **Settings → Actions → General**
2. Scroll to **"Workflow permissions"**
3. Select **"Read and write permissions"**
4. Check **"Allow GitHub Actions to create and approve pull requests"**
5. Click **Save**

---

## 🎯 Creating an Account Request

### Option 1: Via GitHub UI (Recommended)

1. Go to: https://github.com/ravishmck/learn-terraform-aft-account-request/actions
2. Click **"Create AFT Account Request"** workflow
3. Click **"Run workflow"** button (green button on the right)
4. Fill in the form:

   ```yaml
   Account Name: MyNewAccount
   Account Email: my-new-account@example.com
   Organizational Unit: AFTLearn
   SSO User Email: admin@example.com
   SSO User First Name: Your
   SSO User Last Name: Name
   Environment: Dev
   Customizations: sandbox
   Change Reason: Testing GitHub Actions workflow
   ```

5. Click **"Run workflow"**
6. Wait ~2 minutes for workflow to complete
7. Check the workflow summary for monitoring links

### Option 2: Via GitHub CLI

```bash
gh workflow run create-account-request.yml \
  --repo ravishmck/learn-terraform-aft-account-request \
  --field account_name="MyNewAccount" \
  --field account_email="my-new-account@example.com" \
  --field organizational_unit="AFTLearn" \
  --field sso_user_email="admin@example.com" \
  --field sso_user_first_name="Your" \
  --field sso_user_last_name="Name" \
  --field environment="Dev" \
  --field customizations="sandbox" \
  --field change_reason="Testing via CLI"
```

---

## 📊 What Happens Automatically

```
1. Workflow generates Terraform code
2. Commits to terraform/main.tf
3. Pushes to GitHub (triggers pipeline)
4. Triggers AFT CodePipeline in AWS
5. Terraform applies (3-5 min)
6. Account request → DynamoDB
7. AFT automation picks it up (5 min)
8. Step Functions creates account (30-45 min)
9. ✅ Account ready!
```

**Total Time**: ~40-50 minutes from workflow run to account ready

---

## 🔍 Monitoring Your Request

### Check Workflow Status

1. Go to: https://github.com/ravishmck/learn-terraform-aft-account-request/actions
2. Click on your workflow run
3. View the summary for:
   - ✅ Pipeline execution ID
   - 🔗 Direct AWS Console links
   - ⏱️ Expected completion time

### Check AWS Status

Run the status checker:
```bash
cd /Users/ravish_sankhyan-guva/Devops-Sre-Aft/MCK-aft
./check-account-status.sh
```

Or check AWS Console directly:
- [CodePipeline](https://ap-south-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/ct-aft-account-request/view)
- [Step Functions](https://ap-south-1.console.aws.amazon.com/states/home?region=ap-south-1)
- [Organizations](https://console.aws.amazon.com/organizations/v2/home/accounts)

---

## 📋 Form Field Reference

| Field | Required | Example | Description |
|-------|----------|---------|-------------|
| **Account Name** | ✅ | `DevTeam-Alpha` | Display name (alphanumeric, spaces, hyphens) |
| **Account Email** | ✅ | `dev-alpha@company.com` | **Must be unique** across all AWS accounts |
| **Organizational Unit** | ✅ | `AFTLearn` | OU where account will be placed |
| **SSO User Email** | ✅ | `admin@company.com` | Email for SSO access |
| **SSO First Name** | ✅ | `John` | First name for SSO user |
| **SSO Last Name** | ✅ | `Doe` | Last name for SSO user |
| **Environment** | ✅ | `Dev` / `Test` / `Staging` / `Prod` | Environment tag |
| **Customizations** | ✅ | `sandbox` / `production` / `none` | Template to apply |
| **Change Reason** | ✅ | `New dev environment` | Audit trail |

### Email Tips

**Unique emails required!** Use these strategies:

**Gmail:**
- `yourname+dev1@gmail.com`
- `yourname+dev2@gmail.com`
- `yourname+prod@gmail.com`

**Custom Domain:**
- `aws-dev@company.com`
- `aws-staging@company.com`
- `aws-prod@company.com`

---

## 🎉 Example: Creating a Dev Account

Let's create a development account step-by-step:

### 1. Start the Workflow

Navigate to: https://github.com/ravishmck/learn-terraform-aft-account-request/actions/workflows/create-account-request.yml

Click **"Run workflow"**

### 2. Fill the Form

```yaml
Account Name: DevTeam-WebApp
Account Email: dev-webapp@yourcompany.com
Organizational Unit: AFTLearn
SSO User Email: your.email@yourcompany.com
SSO User First Name: Your
SSO User Last Name: Name
Environment: Dev
Customizations: sandbox
Change Reason: Development environment for web application team
```

### 3. Submit and Monitor

- Click **"Run workflow"**
- Wait 1-2 minutes for workflow to complete
- Check workflow summary for:
  - ✅ Commit SHA
  - ✅ Pipeline execution ID
  - 🔗 Monitoring links

### 4. Wait for Account

- **5 minutes**: Request appears in DynamoDB
- **15 minutes**: Step Functions execution starts
- **45 minutes**: Account fully provisioned

### 5. Verify

```bash
# Check status
./check-account-status.sh

# Or via AWS CLI
aws organizations list-accounts \
  --profile ct-mgmt \
  --query 'Accounts[?Email==`dev-webapp@yourcompany.com`]'
```

---

## 🛠️ Troubleshooting

### ❌ Workflow fails: "Permission denied"

**Fix**: Enable write permissions
1. Settings → Actions → General
2. Workflow permissions → **Read and write**

### ❌ Workflow fails: "Could not assume role"

**Fix**: Verify secrets are set correctly
```bash
# Test credentials
aws sts get-caller-identity --profile ct-mgmt
```

### ❌ Pipeline triggered but no account

**Fix**: Check EventBridge rules
```bash
aws events list-rules \
  --region ap-south-1 \
  --profile ct-mgmt \
  --query 'Rules[?contains(Name, `aft-account`)]'
```

### ❌ Email already exists

**Fix**: Use a different email address. Each AWS account needs unique email.

---

## 📚 Additional Documentation

- **Full Guide**: [README-GITHUB-ACTIONS.md](learn-terraform-aft-account-request/README-GITHUB-ACTIONS.md)
- **AFT Automation**: [AFT-AUTOMATION-SUMMARY.md](AFT-AUTOMATION-SUMMARY.md)
- **Status Checker**: [check-account-status.sh](check-account-status.sh)

---

## 🔗 Quick Links

### Your Repository
- [Account Request Repo](https://github.com/ravishmck/learn-terraform-aft-account-request)
- [Actions Tab](https://github.com/ravishmck/learn-terraform-aft-account-request/actions)
- [Workflow File](.github/workflows/create-account-request.yml)

### AWS Console (AFT Management - 809574937450)
- [CodePipeline](https://ap-south-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/ct-aft-account-request/view?region=ap-south-1)
- [Step Functions](https://ap-south-1.console.aws.amazon.com/states/home?region=ap-south-1#/statemachines)
- [DynamoDB](https://ap-south-1.console.aws.amazon.com/dynamodbv2/home?region=ap-south-1#item-explorer?table=aft-request)

### AWS Console (CT Management - 535355705679)
- [Organizations](https://console.aws.amazon.com/organizations/v2/home/accounts)

---

## 💡 Pro Tips

1. **Test First**: Create a test account with `sandbox` customizations before production accounts
2. **Naming Convention**: Use consistent naming like `{Team}-{Purpose}-{Env}`
3. **Tagging**: Environment tags help with cost allocation
4. **Monitoring**: Check workflow summary immediately after run for quick status
5. **Audit Trail**: Change reason field is important for compliance

---

**🎉 You're all set! Create your first account now:**

👉 https://github.com/ravishmck/learn-terraform-aft-account-request/actions/workflows/create-account-request.yml

---

**Last Updated**: 2025-12-05  
**Version**: 1.0  
**Status**: ✅ Tested and Working

