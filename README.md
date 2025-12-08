# MCK-AFT: AWS Account Factory for Terraform

Complete AWS Account Factory for Terraform (AFT) implementation for automated AWS account provisioning and management.

## 🚀 Quick Start

### Create New AWS Account

**👉 Go to:** https://github.com/ravishmck/learn-terraform-aft-account-request/actions

1. Click **"🚀 Create AWS Account Request"**
2. Click **"Run workflow"** → Fill the 4-field form
3. Wait ~20 minutes → Account appears in Organizations!

[**📖 Full Guide**](docs/HOW-TO-CREATE-ACCOUNTS.md)

### Check Account Status

```bash
./scripts/check-account-status.sh
```

### Monitor AFT

- **CodePipeline**: https://ap-south-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/ct-aft-account-request/view
- **Step Functions**: https://ap-south-1.console.aws.amazon.com/states/home?region=ap-south-1
- **Organizations**: https://console.aws.amazon.com/organizations/v2/home/accounts

---

## 📁 Repository Structure

```
MCK-aft/
├── docs/                              # Documentation
│   ├── AFT-AUTOMATION-SUMMARY.md      # Complete setup guide
│   └── GITHUB-ACTIONS-QUICKSTART.md   # Quick reference
│
├── scripts/                           # Utility scripts
│   └── check-account-status.sh        # Account provisioning status
│
├── learn-terraform-aft-account-request/
│   └── terraform/                     # Account request definitions
│
├── learn-terraform-aft-account-customizations/
│   └── sandbox/                       # Account-specific customizations
│
├── learn-terraform-aft-account-provisioning-customizations/
│   └── terraform/                     # Provisioning customizations
│
├── learn-terraform-aft-global-customizations/
│   └── terraform/                     # Global customizations for all accounts
│
└── learn-terraform-aws-control-tower-aft/
    ├── main.tf                        # AFT infrastructure
    ├── backend.tf                     # Terraform state configuration
    └── terraform.tfvars               # AFT configuration values
```

---

## 🎯 What is AFT?

AWS Account Factory for Terraform (AFT) provides a GitOps-based approach to:
- **Automate** AWS account provisioning
- **Standardize** account configurations
- **Manage** account customizations at scale
- **Audit** account creation and changes

### Key Components

| Component | Purpose |
|-----------|---------|
| **Control Tower AFT** | Core AFT infrastructure (436 resources) |
| **Account Request** | Define new AWS accounts to provision |
| **Global Customizations** | Apply to ALL accounts |
| **Account Customizations** | Apply to specific accounts |
| **Provisioning Customizations** | Run during account creation |

---

## 🏗️ Architecture

### Accounts

| Account | Account ID | Purpose |
|---------|------------|---------|
| **CT Management** | 535355705679 | Control Tower management |
| **AFT Management** | 809574937450 | AFT infrastructure |
| **Log Archive** | 180574905686 | Centralized logging |
| **Audit** | 002506421448 | Security and compliance |

### AFT Workflow

```
1. Account Request (Git Commit)
   ↓
2. CodePipeline Triggered
   ↓
3. Terraform Apply → DynamoDB
   ↓
4. EventBridge Scheduler (5 min)
   ↓
5. Lambda Processor
   ↓
6. Step Functions Execution
   ↓
7. Control Tower Account Creation
   ↓
8. AFT Customizations Applied
   ↓
9. Account Ready! ✅
```

---

## 📋 Creating Account Requests

### Method 1: Edit main.tf Directly

```bash
cd learn-terraform-aft-account-request/terraform
vi main.tf
```

Add a new module block:

```hcl
module "my_new_account" {
  source = "./modules/aft-account-request"

  control_tower_parameters = {
    AccountEmail              = "unique-email@example.com"
    AccountName               = "MyNewAccount"
    ManagedOrganizationalUnit = "AFTLearn"
    SSOUserEmail              = "admin@example.com"
    SSOUserFirstName          = "Admin"
    SSOUserLastName           = "User"
  }

  account_tags = {
    "Environment" = "Dev"
    "ManagedBy"   = "AFT"
  }

  change_management_parameters = {
    change_requested_by = "Your Name"
    change_reason       = "Development environment"
  }

  custom_fields = {
    group = "engineering"
  }

  account_customizations_name = "sandbox"
}
```

### Method 2: Use Status Checker

Monitor account provisioning progress:

```bash
./scripts/check-account-status.sh
```

---

## ⚙️ Configuration

### AWS Credentials

AFT uses the `ct-mgmt` AWS CLI profile:

```bash
export AWS_PROFILE=ct-mgmt
aws sts get-caller-identity
```

### Terraform Backend

State stored in S3 with DynamoDB locking:
- **Bucket**: `mck-aft-terraform-state-535355705679`
- **Table**: `mck-aft-terraform-state-lock`
- **Region**: `ap-south-1`

---

## 🔍 Monitoring & Troubleshooting

### Check Account Status

```bash
./scripts/check-account-status.sh
```

### View CloudWatch Logs

```bash
aws logs tail /aws/lambda/aft-account-request-processor --follow --region ap-south-1
```

### Common Issues

**Account not appearing?**
1. Check DynamoDB: `aft-request` table
2. Verify Step Functions executions
3. Check CloudWatch Logs for errors
4. Confirm OU exists in Organizations

**Pipeline not triggering?**
- AFT uses EventBridge schedulers (every 5 minutes)
- Manually trigger: `aws codepipeline start-pipeline-execution --name ct-aft-account-request --region ap-south-1`

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [AFT Automation Summary](docs/AFT-AUTOMATION-SUMMARY.md) | Complete setup and troubleshooting guide |
| [GitHub Actions Guide](docs/GITHUB-ACTIONS-QUICKSTART.md) | Workflow automation reference |
| [Status Checker Script](scripts/check-account-status.sh) | Monitor account provisioning |

---

## 🚦 Account Provisioning Timeline

| Time | Status |
|------|--------|
| 0 min | Request committed to Git |
| 5 min | CodePipeline completes |
| 10 min | AFT detects request |
| 15 min | Step Functions starts |
| 45 min | **Account fully provisioned** ✅ |

---

## 🔐 Security Notes

- All AWS credentials stored in `~/.aws/credentials`
- IAM roles use least-privilege permissions
- State files encrypted at rest (S3 + KMS)
- DynamoDB tables have encryption enabled
- CloudTrail logs all API activity

---

## 🆘 Support & Resources

### AWS Console Links

**AFT Management Account (809574937450)**
- [CodePipeline](https://ap-south-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/ct-aft-account-request/view)
- [Step Functions](https://ap-south-1.console.aws.amazon.com/states/home?region=ap-south-1)
- [DynamoDB Tables](https://ap-south-1.console.aws.amazon.com/dynamodbv2/home?region=ap-south-1)
- [Lambda Functions](https://ap-south-1.console.aws.amazon.com/lambda/home?region=ap-south-1#/functions)

**CT Management Account (535355705679)**
- [AWS Organizations](https://console.aws.amazon.com/organizations/v2/home/accounts)
- [Control Tower](https://console.aws.amazon.com/controltower/home)

### External Resources

- [AWS AFT Documentation](https://docs.aws.amazon.com/controltower/latest/userguide/aft-getting-started.html)
- [AFT GitHub Repository](https://github.com/aws-ia/terraform-aws-control_tower_account_factory)
- [Control Tower Guide](https://docs.aws.amazon.com/controltower/latest/userguide/what-is-control-tower.html)

---

## 🔄 Maintenance

### Update AFT Infrastructure

```bash
cd learn-terraform-aws-control-tower-aft
terraform plan
terraform apply
```

### Update Submodules

```bash
git submodule update --remote
```

### Backup State

State is automatically versioned in S3 with 30-day retention.

---

## 👥 Contributors

Maintained by the DevOps Team

---

## 📝 Version History

- **v1.0.0** - Initial AFT deployment (436 resources)
- **v1.1.0** - Added EventBridge automation
- **v1.2.0** - Lambda layer fixes and IAM improvements

---

**Last Updated**: December 5, 2025  
**AFT Version**: 1.17.0  
**Terraform Version**: Latest compatible  
**AWS Region**: ap-south-1 (primary), us-east-1 (secondary)
