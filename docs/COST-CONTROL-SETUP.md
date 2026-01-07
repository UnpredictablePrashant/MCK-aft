# 💰 Cost Control Setup Guide

This guide explains the cost control mechanisms in place for AWS accounts created by AFT.

---

## 🎯 Overview

Every AWS account created through AFT automatically gets:

| Feature | Value | Purpose |
|---------|-------|---------|
| **AWS Budget** | $200/month | Alerts when spending approaches limit |
| **Email Alerts** | 80%, 90%, 100% | Proactive spending notifications |
| **Forecasted Alerts** | 100%, 110% | Warns before overspending |
| **Service Control Policy** | Optional | Blocks expensive services |

---

## 📊 Automatic AWS Budgets

### What Gets Created

When AFT provisions a new account, it automatically creates:

```
Budget Name: monthly-budget-200-usd
Limit: $200 USD per month
Alerts:
  - 80% ($160) - Actual spending
  - 90% ($180) - Actual spending
  - 100% ($200) - Actual spending
  - 100% - Forecasted spending
  - 110% - Forecasted spending
```

### Alert Email Format

When a threshold is crossed:

```
From: AWS Budgets <no-reply@budgets.amazonaws.com>
Subject: AWS Budgets: Budget Alert for monthly-budget-200-usd

Your budget "monthly-budget-200-usd" has exceeded 80% of $200.00
Account: 123456789012
Current spending: $163.50
Forecasted spending: $245.00
```

### Where It's Configured

The budget Terraform code is in:

```
learn-terraform-aft-account-customizations/sandbox/terraform/budgets/budget.tf
```

**Key Configuration:**

```hcl
resource "aws_budgets_budget" "monthly_cost_budget" {
  name              = "monthly-budget-200-usd"
  budget_type       = "COST"
  limit_amount      = "200"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  
  # Alert at 80% ($160)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["ravish.snkhyn@gmail.com"]
  }
  
  # Additional notifications at 90%, 100%, forecasted...
}
```

---

## 🛡️ Service Control Policies (SCPs)

### What SCPs Do

SCPs are **guardrails** that prevent certain AWS API actions. They don't grant permissions—they set maximum allowable actions.

### Available SCP: Deny Expensive Services

**Location:** `policies/scp/deny-expensive-services.json`

**What It Blocks:**

| Service | Reason |
|---------|--------|
| ❌ SageMaker | ML training can cost $1000s/day |
| ❌ Redshift | Data warehousing is expensive |
| ❌ EMR | Big data clusters are costly |
| ❌ Large EC2 | Only t2/t3 small instances allowed |
| ❌ Large EBS | Max 100GB volumes |
| ❌ ElastiCache/RDS | Only small instances allowed |

**What It Allows:**

| Service | Types Allowed |
|---------|---------------|
| ✅ EC2 | t2.micro, t2.small, t3.micro, t3.small, t3a.micro, t3a.small |
| ✅ EBS | Up to 100GB volumes |
| ✅ Lambda | All (serverless, pay-per-use) |
| ✅ S3 | All (pay-per-use) |
| ✅ DynamoDB | All (pay-per-use) |
| ✅ API Gateway | All (pay-per-use) |

### How to Apply SCP

**Quick Method - Use the Script:**

```bash
bash scripts/apply-scp.sh
```

This interactive script:
1. Creates the SCP in AWS Organizations
2. Asks which OU to apply it to
3. Attaches the policy

**Manual Method:**

```bash
# 1. Create the policy
aws organizations create-policy \
  --name "DenyExpensiveServices" \
  --description "Prevents expensive AWS services" \
  --type SERVICE_CONTROL_POLICY \
  --content file://policies/scp/deny-expensive-services.json \
  --profile ct-mgmt

# 2. Attach to an OU (e.g., Batch14)
aws organizations attach-policy \
  --policy-id p-xxxxxxxx \
  --target-id ou-hn55-97mt9432 \
  --profile ct-mgmt
```

### OU Target IDs

| OU Name | ID | Apply SCP? |
|---------|-----|------------|
| LearnMck | `ou-hn55-ambq41wc` | ✅ Yes |
| Sandbox | `ou-hn55-8v2p3o33` | ✅ Yes |
| Batch14 | `ou-hn55-97mt9432` | ✅ Yes |
| Batch15 | `ou-hn55-si8zml39` | ✅ Yes |
| AFT-Lab-Rajesh | `ou-hn55-j1275av7` | ⚠️ Optional |
| Security | `ou-hn55-nk6je9rf` | ❌ No |

---

## 🔧 Customizing Cost Controls

### Change Budget Limit

Edit the budget amount in:
`learn-terraform-aft-account-customizations/sandbox/terraform/budgets/budget.tf`

```hcl
limit_amount = "300"  # Change from 200 to 300
```

Then trigger account customizations to apply.

### Change Alert Email

Update the email addresses in the notification blocks:

```hcl
notification {
  subscriber_email_addresses = ["your-email@example.com"]
}
```

### Add More Alert Thresholds

Add additional notification blocks:

```hcl
# Alert at 50% ($100)
notification {
  comparison_operator        = "GREATER_THAN"
  threshold                  = 50
  threshold_type             = "PERCENTAGE"
  notification_type          = "ACTUAL"
  subscriber_email_addresses = ["your-email@example.com"]
}
```

### Modify SCP Rules

Edit `policies/scp/deny-expensive-services.json`:

**Allow larger EC2 instances:**
```json
"ec2:InstanceType": [
  "t2.micro",
  "t2.small",
  "t2.medium",  // Add this
  "t3.micro",
  "t3.small",
  "t3.medium"   // Add this
]
```

**Allow larger EBS volumes:**
```json
"Condition": {
  "NumericGreaterThan": {
    "ec2:VolumeSize": "200"  // Change from 100 to 200
  }
}
```

---

## 📈 Monitoring Costs

### Via AWS Console

**Cost Explorer:**
```
https://console.aws.amazon.com/cost-management/home#/cost-explorer
```

**Budgets Dashboard:**
```
https://console.aws.amazon.com/billing/home#/budgets
```

### Via AWS CLI

**Check current month spending:**
```bash
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --query 'ResultsByTime[0].Total.UnblendedCost.Amount'
```

**List all budgets:**
```bash
aws budgets describe-budgets \
  --account-id $(aws sts get-caller-identity --query Account --output text)
```

---

## 🚨 What Happens When Limits Are Hit

### Budget Alerts

| Threshold | Action |
|-----------|--------|
| 80% ($160) | Email warning sent |
| 90% ($180) | Email warning sent |
| 100% ($200) | Email alert - at limit! |
| Forecasted 100% | Email warning - projected overage |

**Important:** Budget alerts are **informational only**. They do NOT stop AWS services.

### SCP Enforcement

When SCP is applied, blocked actions return:

```
An error occurred (AccessDeniedException): User: arn:aws:iam::123456789012:user/student 
is not authorized to perform: ec2:RunInstances on resource: * 
with an explicit deny in a service control policy
```

**This immediately prevents the action.**

---

## 📋 Quick Reference

### Check If Budget Exists

```bash
aws budgets describe-budgets \
  --account-id YOUR_ACCOUNT_ID \
  --query "Budgets[?BudgetName=='monthly-budget-200-usd']"
```

### Check If SCP Is Applied

```bash
aws organizations list-policies-for-target \
  --target-id ou-hn55-97mt9432 \
  --filter SERVICE_CONTROL_POLICY \
  --profile ct-mgmt
```

### Test SCP (Should Fail)

```bash
# This should be DENIED if SCP is active:
aws ec2 run-instances \
  --instance-type m5.large \
  --image-id ami-xxxxxxxx
# Expected: AccessDeniedException
```

### Test SCP (Should Succeed)

```bash
# This should SUCCEED if SCP is active:
aws ec2 run-instances \
  --instance-type t3.micro \
  --image-id ami-xxxxxxxx
# Expected: Instance launches
```

---

## 🎯 Best Practices

### For Training/Student Accounts

1. ✅ Apply $200 budget (automatic)
2. ✅ Apply SCP to block expensive services
3. ✅ Use email alerts for visibility
4. ✅ Place in dedicated OU (Batch14, Batch15)

### For Development Accounts

1. ✅ Apply $200-500 budget
2. ⚠️ Consider looser SCP
3. ✅ Enable forecasted alerts
4. ✅ Monitor weekly via Cost Explorer

### For Production Accounts

1. ✅ Higher budget limits
2. ❌ No restrictive SCP
3. ✅ Multiple alert thresholds
4. ✅ Daily monitoring

---

## 🔗 Related Documentation

- [Service Control Policies README](../policies/scp/README.md)
- [Apply SCP Script](../scripts/apply-scp.sh)
- [Budget Terraform Code](../learn-terraform-aft-account-customizations/sandbox/terraform/budgets/budget.tf)
- [AFT Architecture](./AFT-ARCHITECTURE-NO-NAT.md)

---

## 💡 Tips

### Gmail + Trick for Multiple Accounts

Use email aliases to receive all budget alerts in one inbox:
```
ravish.snkhyn+account1@gmail.com
ravish.snkhyn+account2@gmail.com
```

All emails go to `ravish.snkhyn@gmail.com`!

### Set Up Cost Anomaly Detection

For additional protection, enable AWS Cost Anomaly Detection:
```bash
aws ce create-anomaly-monitor \
  --monitor-name "Monthly-Spend-Monitor" \
  --monitor-type DIMENSIONAL \
  --monitor-dimension SERVICE
```

---

**Last Updated:** January 2026  
**Applies to:** All AFT-created accounts  
**Questions?** Check [Troubleshooting](./TROUBLESHOOTING.md)

