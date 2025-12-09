# AWS Account Factory for Terraform (AFT)

Automated AWS account provisioning using Control Tower and Terraform - optimized for cost efficiency and ease of use.

## 🎯 Quick Start

### Create Single Account
1. Go to: [Create Account Workflow](https://github.com/ravishmck/learn-terraform-aft-account-request/actions/workflows/create-account.yml)
2. Click "Run workflow"
3. Fill in account details
4. ✅ Account created in ~20 minutes with $200 budget

### Create Multiple Accounts (Bulk)
1. Go to: [Bulk Creation Workflow](https://github.com/ravishmck/learn-terraform-aft-account-request/actions/workflows/create-bulk-accounts-csv.yml)
2. Click "Run workflow"  
3. Enter CSV format: `Name,Email,OU,Environment`
4. ✅ All accounts created in ~20 minutes

### Close Account
1. Go to: [Close Account Workflow](https://github.com/ravishmck/learn-terraform-aft-account-request/actions/workflows/close-account.yml)
2. Click "Run workflow"
3. Enter account details
4. ✅ Account decommissioned

---

## 📚 Documentation

| Guide | Description |
|-------|-------------|
| [How to Create Accounts](docs/HOW-TO-CREATE-ACCOUNTS.md) | Step-by-step single account creation |
| [Bulk Account Creation](docs/BULK-ACCOUNT-CREATION.md) | Create multiple accounts at once |
| [How to Close Accounts](docs/HOW-TO-CLOSE-ACCOUNTS.md) | Decommission accounts |
| [Cost Control Setup](docs/COST-CONTROL-SETUP.md) | $200 budget & SCP enforcement |
| [Get AWS Credentials](docs/GET-AWS-CREDENTIALS.md) | Set up CLI access |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Common issues and fixes |

---

## 🏗️ Architecture

### Cost-Optimized Design
- ✅ **No NAT Gateways** - Saves ~$768/year
- ✅ **No VPC for Lambda/CodeBuild** - Free AWS internet access
- ✅ **$200/month budget per account** - Automatic alerts
- ✅ **Service Control Policies** - Prevent expensive services

### Workflow
```
GitHub → CodePipeline → CodeBuild → DynamoDB → Lambda → Service Catalog → Account (ACTIVE)
         (Auto every 2min)  (No VPC!)              (No VPC!)
```

[Architecture Details](docs/AFT-ARCHITECTURE-NO-NAT.md) | [NAT Removal Guide](docs/NAT-GATEWAY-REMOVAL-GUIDE.md)

---

## 💰 Cost Control

Every account automatically gets:
- ✅ $200 monthly budget limit
- ✅ Email alerts at 80%, 90%, 100%
- ✅ Forecasted spending alerts
- ⚠️ Optional SCP to block expensive services

[Full Cost Control Guide](docs/COST-CONTROL-SETUP.md)

---

## 🔧 Available OUs

- **LearnMck** - Learning/Training accounts
- **Sandbox** - Experimentation/Dev
- **Batch14** - Student batch 14
- **Batch15** - Student batch 15  
- **AFT-Lab-Rajesh** - Lab environment
- **Security** - Security tools
- **SuspendedAccount** - Archived accounts

---

## 📊 What Gets Created

When you request an account, AFT automatically:
1. ✅ Creates AWS account via Control Tower
2. ✅ Sets up SSO access
3. ✅ Configures $200 monthly budget
4. ✅ Applies baseline security (Control Tower)
5. ✅ Runs customizations (if configured)
6. ✅ Sends you email alerts
7. ✅ Makes account ACTIVE (~20 minutes)

---

## 🚀 Features

### Automated Workflows
- ✅ Single account creation via GitHub Actions
- ✅ Bulk account creation (CSV format)
- ✅ Account decommissioning
- ✅ Auto-trigger on git push (every 2 minutes)
- ✅ End-to-end monitoring

### Cost Management  
- ✅ $200 budget per account (automatic)
- ✅ Email alerts at thresholds
- ✅ Service Control Policies (optional)
- ✅ No NAT Gateway costs

### Easy to Use
- ✅ GitHub Actions UI (no CLI needed)
- ✅ Copy-paste from Excel for bulk creation
- ✅ Comprehensive documentation
- ✅ Troubleshooting guides

---

## 🛠️ Technical Details

### Repositories
- **Main**: MCK-aft (this repo)
- **Account Requests**: [learn-terraform-aft-account-request](https://github.com/ravishmck/learn-terraform-aft-account-request)
- **Account Customizations**: learn-terraform-aft-account-customizations
- **Global Customizations**: learn-terraform-aft-global-customizations

### AWS Accounts
- **Management**: 535355705679 (HV_academics)
- **AFT Management**: 809574937450 (AFTLearn)
- **Log Archive**: 180574905686
- **Audit**: 002506421448

### Key Components
- **CodePipeline**: ct-aft-account-request (auto-triggers every 2 min)
- **DynamoDB**: aft-request table
- **Step Functions**: aft-account-provisioning-framework
- **Lambda Functions**: 17 functions (all without VPC)

---

## 📞 Quick Links

- [GitHub Actions Workflows](https://github.com/ravishmck/learn-terraform-aft-account-request/actions)
- [CodePipeline](https://ap-south-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/ct-aft-account-request/view)
- [DynamoDB Table](https://ap-south-1.console.aws.amazon.com/dynamodbv2/home?region=ap-south-1#table?name=aft-request)
- [AWS Organizations](https://console.aws.amazon.com/organizations/v2/home/accounts)

---

## 🎓 Common Use Cases

### Student Batch Creation
Create 20+ accounts for a training batch in one go:
```csv
Batch14Student01,student01@training.com,Batch14,Development
Batch14Student02,student02@training.com,Batch14,Development
...
```
[Bulk Creation Guide](docs/BULK-ACCOUNT-CREATION.md)

### Multi-Environment Setup
Create Dev, Test, Staging, Prod accounts:
```csv
ProjectX-Dev,proj+dev@company.com,Sandbox,Development
ProjectX-Test,proj+test@company.com,Sandbox,Testing
ProjectX-Stage,proj+stage@company.com,LearnMck,Staging
ProjectX-Prod,proj+prod@company.com,LearnMck,Production
```

### Team Sandboxes
Give each team member their own AWS account for experimentation.

---

## 🔍 Monitoring

### Account Creation Progress
1. **GitHub Actions** - See workflow status
2. **CodePipeline** - Monitor terraform apply
3. **DynamoDB** - Check if request was recorded
4. **Organizations** - See when account becomes ACTIVE

### Typical Timeline
- 0-2 min: Request pushed to GitHub
- 2-5 min: CodePipeline runs terraform apply
- 5-10 min: DynamoDB entry created, Lambda triggered
- 10-20 min: Account created and ACTIVE

---

## ⚙️ Maintenance

### Update AFT
```bash
cd learn-terraform-aws-control-tower-aft
git pull
terraform apply
```

### Apply SCP (One-time)
```bash
bash scripts/apply-scp.sh
```

### Increase Account Limit
See [Service Quota Increase Guide](docs/SERVICE-QUOTA-INCREASE.md)

---

## 📖 Additional Resources

- [AFT Fix Summary](docs/AFT-FIX-SUMMARY.md) - What was fixed (Lambda VPC removal, etc.)
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues
- [AWS AFT Official Docs](https://docs.aws.amazon.com/controltower/latest/userguide/aft-overview.html)

---

## 🎉 Summary

This AFT setup provides:
- ✅ **Automated** account creation via GitHub Actions
- ✅ **Cost-optimized** with no NAT Gateway (~$768/year savings)
- ✅ **Budget-protected** with $200/month limits
- ✅ **Easy to use** with simple workflows
- ✅ **Bulk capable** for student batches or teams
- ✅ **Well-documented** with comprehensive guides

**Start creating accounts now:** [GitHub Actions Workflows](https://github.com/ravishmck/learn-terraform-aft-account-request/actions)
