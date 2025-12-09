# 💰 Cost Control Setup - $200 Budget Enforcement

## Overview

This guide sets up **TWO layers** of cost control for your AFT-created accounts:

1. **AWS Budgets** (automatic) - Sends alerts when spending approaches $200
2. **Service Control Policies** (manual) - Prevents expensive AWS services

---

## ✅ Layer 1: AWS Budgets (AUTOMATIC)

### What It Does
- ✅ **Automatically applied** to every new account created via AFT
- ✅ Sets $200/month spending limit
- ✅ Sends email alerts at 80%, 90%, 100% ($160, $180, $200)
- ✅ Forecasted alert when projected to exceed $200

### Already Configured!
The budget enforcement is **already included** in your AFT account customizations:

```
learn-terraform-aft-account-customizations/
└── sandbox/
    └── terraform/
        ├── main.tf           # Includes budget module
        └── budgets/
            └── budget.tf      # $200 budget configuration
```

### How It Works
1. User requests account via GitHub Actions
2. AFT creates the account
3. AFT automatically runs customizations
4. Budget is created with $200 limit
5. Email alerts are configured
6. ✅ Done! Budget is active.

### Email Alerts You'll Receive

| Threshold | Amount | When You Get Alert |
|-----------|--------|-------------------|
| 80% | $160 | When actual spending reaches $160 |
| 90% | $180 | When actual spending reaches $180 |
| 100% | $200 | When actual spending reaches $200 |
| Forecasted 100% | $200 | When AWS predicts you'll hit $200 this month |

### Customizing Alert Email

Edit this file:
```bash
learn-terraform-aft-account-customizations/sandbox/terraform/budgets/budget.tf
```

Change line 32:
```terraform
endpoint  = "ravish.snkhyn@gmail.com"  # ← Change to your email
```

And lines 47, 57, 67, 77:
```terraform
subscriber_email_addresses = ["your.email@example.com"]
```

### Testing the Budget

After creating a new account:

```bash
# Check if budget was created
aws budgets describe-budgets \
  --account-id <NEW_ACCOUNT_ID> \
  --profile ct-mgmt

# View budget details
aws budgets describe-budget \
  --account-id <NEW_ACCOUNT_ID> \
  --budget-name monthly-budget-200-usd \
  --profile ct-mgmt
```

---

## 🛡️ Layer 2: Service Control Policies (MANUAL - One-time setup)

### What It Does
- ❌ **Blocks** expensive AWS services before they can be used
- ❌ **Denies** large EC2 instances (only allows t2/t3/t3a small instances)
- ❌ **Prevents** large EBS volumes (max 100GB)
- ❌ **Stops** SageMaker, Redshift, EMR from being used

### What It DOESN'T Block
- ✅ Lambda (serverless - cost-effective)
- ✅ S3 (pay-per-use)
- ✅ DynamoDB (serverless)
- ✅ t2.micro, t2.small, t3.micro, t3.small instances
- ✅ API Gateway, CloudWatch, IAM, etc.

### Quick Apply (Recommended)

Run the automated script:

```bash
bash /Users/ravish_sankhyan-guva/Devops-Sre-Aft/MCK-aft/scripts/apply-scp.sh
```

This script will:
1. Create the "DenyExpensiveServices" policy
2. Let you choose which OUs to protect
3. Attach the policy automatically

**Recommended OUs to protect:**
- ✅ LearnMck
- ✅ Sandbox
- ✅ Batch14
- ✅ Batch15

### Manual Apply

If you prefer manual control:

```bash
# 1. Create the policy
aws organizations create-policy \
  --name "DenyExpensiveServices" \
  --description "Prevents expensive services to keep costs under $200" \
  --type SERVICE_CONTROL_POLICY \
  --content file://policies/scp/deny-expensive-services.json \
  --profile ct-mgmt

# Output: "Id": "p-xxxxxxxx"

# 2. Attach to LearnMck OU
aws organizations attach-policy \
  --policy-id p-xxxxxxxx \
  --target-id ou-hn55-ambq41wc \
  --profile ct-mgmt
```

### Testing the SCP

After applying, test in one of your accounts:

```bash
# This should FAIL (instance too large):
aws ec2 run-instances \
  --image-id ami-0dee22c13ea7a9a67 \
  --instance-type m5.large \
  --count 1

# Error: "You are not authorized to perform this operation"

# This should SUCCEED (allowed instance):
aws ec2 run-instances \
  --image-id ami-0dee22c13ea7a9a67 \
  --instance-type t3.micro \
  --count 1

# ✅ Instance launches successfully!
```

---

## 📊 Complete Cost Control Strategy

### For New Accounts (Automatic)
1. ✅ User requests account via GitHub Actions
2. ✅ AFT creates account
3. ✅ Budget ($200 limit) is automatically applied
4. ✅ Email alerts configured
5. ✅ Account ready to use

### For Organizational Units (One-time manual)
1. Run: `bash scripts/apply-scp.sh`
2. Select OUs to protect (LearnMck, Sandbox, etc.)
3. ✅ SCP applied to entire OU
4. ✅ All accounts in that OU are protected

### Result
- 🛡️ **Prevention**: SCP stops expensive services BEFORE use
- 💰 **Monitoring**: Budget sends alerts as costs increase  
- 📧 **Alerts**: Email at $160, $180, $200
- 🎯 **Target**: Keep all accounts under $200/month

---

## 📋 Quick Reference

### Budget Files
```
learn-terraform-aft-account-customizations/sandbox/terraform/
├── main.tf              # Calls budget module
└── budgets/
    └── budget.tf        # $200 budget config
```

### SCP Files
```
policies/scp/
├── deny-expensive-services.json  # The actual policy
└── README.md                     # Detailed SCP docs
```

### Scripts
```
scripts/
└── apply-scp.sh         # Automated SCP deployment
```

---

## 🔧 Troubleshooting

### Budget Not Created for New Account

Check AFT customizations ran:

```bash
# View Step Functions execution
aws stepfunctions list-executions \
  --state-machine-arn arn:aws:states:ap-south-1:809574937450:stateMachine:aft-account-customizations \
  --profile ct-mgmt
```

### SCP Not Blocking Actions

Verify it's attached:

```bash
# List policies on an OU
aws organizations list-policies-for-target \
  --target-id ou-hn55-ambq41wc \
  --filter SERVICE_CONTROL_POLICY \
  --profile ct-mgmt
```

### Not Receiving Email Alerts

1. Check SNS subscription in the new account:
```bash
aws sns list-subscriptions --profile <account-profile>
```

2. Confirm email subscription (check inbox/spam)

---

## 📈 Monitoring Costs

### View Current Spending

```bash
# Check budget status
aws budgets describe-budget \
  --account-id <ACCOUNT_ID> \
  --budget-name monthly-budget-200-usd \
  --profile ct-mgmt

# View actual spending
aws ce get-cost-and-usage \
  --time-period Start=2025-12-01,End=2025-12-31 \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --profile ct-mgmt
```

### AWS Console Dashboards

- **Cost Explorer**: https://console.aws.amazon.com/cost-management/home#/cost-explorer
- **Budgets**: https://console.aws.amazon.com/billing/home#/budgets
- **AWS Organizations**: https://console.aws.amazon.com/organizations/v2/home

---

## 🎯 Best Practices

1. ✅ **Always apply SCPs** to training/learning OUs (LearnMck, Batch14, Batch15)
2. ✅ **Keep budget alerts** enabled on all accounts
3. ✅ **Review Cost Explorer** weekly
4. ✅ **Clean up unused resources** (EC2, EBS, snapshots)
5. ✅ **Use t3.micro** for testing (free tier eligible)
6. ✅ **Shut down instances** when not in use

---

## 📞 Summary

| Feature | Type | Status | Action Required |
|---------|------|--------|----------------|
| **AWS Budgets ($200)** | Automatic | ✅ Configured | None - auto-applies to new accounts |
| **Email Alerts** | Automatic | ✅ Configured | Verify email in `budgets/budget.tf` |
| **SCP (Cost Control)** | Manual | ⏳ Pending | Run `scripts/apply-scp.sh` once |

**Next Step:** Run the SCP script to protect your OUs!

```bash
bash /Users/ravish_sankhyan-guva/Devops-Sre-Aft/MCK-aft/scripts/apply-scp.sh
```

