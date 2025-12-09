# Service Control Policies (SCPs) for Cost Management

## Overview

Service Control Policies (SCPs) are policies that specify the maximum permissions for member accounts in your AWS Organization. They **do not grant permissions** but act as guardrails to prevent certain actions.

## Available SCPs

### 1. `deny-expensive-services.json`
Prevents the use of expensive AWS services and enforces cost-effective instance types.

**What it blocks:**
- ❌ SageMaker (ML training can be expensive)
- ❌ Redshift (data warehousing)
- ❌ EMR (big data processing)
- ❌ Large ElastiCache/RDS instances
- ❌ EC2 instances larger than t2/t3/t3a families
- ❌ EBS volumes larger than 100GB

**What it allows:**
- ✅ t2.micro, t2.small
- ✅ t3.micro, t3.small  
- ✅ t3a.micro, t3a.small
- ✅ EBS volumes up to 100GB
- ✅ All serverless services (Lambda, S3, DynamoDB, etc.)

---

## How to Apply SCPs

### Method 1: Apply to Specific OU (Recommended)

This applies the policy to all accounts in an OU (e.g., LearnMck, Sandbox, Batch14):

```bash
# 1. Create the SCP in AWS Organizations
aws organizations create-policy \
  --name "DenyExpensiveServices" \
  --description "Prevents use of expensive AWS services to control costs" \
  --type SERVICE_CONTROL_POLICY \
  --content file://policies/scp/deny-expensive-services.json \
  --profile ct-mgmt

# Output will show: "Id": "p-xxxxxxxx"
# Save this policy ID!

# 2. Attach to an OU (example: LearnMck)
aws organizations attach-policy \
  --policy-id p-xxxxxxxx \
  --target-id ou-hn55-ambq41wc \
  --profile ct-mgmt

# For other OUs:
# LearnMck: ou-hn55-ambq41wc
# Sandbox: ou-hn55-8v2p3o33
# Batch14: ou-hn55-97mt9432
# Batch15: ou-hn55-si8zml39
# AFT-Lab-Rajesh: ou-hn55-j1275av7
# Security: ou-hn55-nk6je9rf
```

### Method 2: Apply to All Accounts at Root Level

**⚠️ WARNING:** This affects ALL accounts in your organization!

```bash
# Create the policy
aws organizations create-policy \
  --name "DenyExpensiveServices" \
  --description "Org-wide cost control policy" \
  --type SERVICE_CONTROL_POLICY \
  --content file://policies/scp/deny-expensive-services.json \
  --profile ct-mgmt

# Attach to root (affects all accounts)
aws organizations attach-policy \
  --policy-id p-xxxxxxxx \
  --target-id r-hn55 \
  --profile ct-mgmt
```

### Method 3: Apply to Specific Account

```bash
# Attach SCP to a single account
aws organizations attach-policy \
  --policy-id p-xxxxxxxx \
  --target-id 765427462492 \
  --profile ct-mgmt
```

---

## Quick Apply Script

I've created a script to make this easier:

```bash
bash /Users/ravish_sankhyan-guva/Devops-Sre-Aft/MCK-aft/scripts/apply-scp.sh
```

---

## Testing the SCP

After applying, test in one of your accounts:

```bash
# This should be DENIED (instance too large):
aws ec2 run-instances \
  --image-id ami-xxxxxxxx \
  --instance-type m5.large \
  --count 1

# Error: "You are not authorized to perform this operation"

# This should SUCCEED (allowed instance type):
aws ec2 run-instances \
  --image-id ami-xxxxxxxx \
  --instance-type t3.micro \
  --count 1
```

---

## Viewing Applied SCPs

```bash
# List all SCPs in organization
aws organizations list-policies \
  --filter SERVICE_CONTROL_POLICY \
  --profile ct-mgmt

# View policies attached to an OU
aws organizations list-policies-for-target \
  --target-id ou-hn55-ambq41wc \
  --filter SERVICE_CONTROL_POLICY \
  --profile ct-mgmt

# View policy content
aws organizations describe-policy \
  --policy-id p-xxxxxxxx \
  --profile ct-mgmt
```

---

## Removing/Updating SCPs

### Detach SCP
```bash
aws organizations detach-policy \
  --policy-id p-xxxxxxxx \
  --target-id ou-hn55-ambq41wc \
  --profile ct-mgmt
```

### Update SCP
```bash
aws organizations update-policy \
  --policy-id p-xxxxxxxx \
  --content file://policies/scp/deny-expensive-services.json \
  --profile ct-mgmt
```

### Delete SCP
```bash
# Must detach from all targets first!
aws organizations delete-policy \
  --policy-id p-xxxxxxxx \
  --profile ct-mgmt
```

---

## Important Notes

1. **SCPs DON'T prevent billing entirely** - they prevent certain API actions
2. **For actual budget enforcement**, use AWS Budgets (see `/learn-terraform-aft-account-customizations/sandbox/terraform/budgets/`)
3. **SCPs affect IAM users, roles, and root user** (except the management account)
4. **Management account** is NOT affected by SCPs
5. **SCPs are inherited** - if applied to root, affects all OUs and accounts

---

## Recommended Strategy

✅ **Best Practice:**
1. Apply SCP to training/learning OUs (LearnMck, Batch14, Batch15, Sandbox)
2. Keep Production OU without SCP (or with less restrictive policy)
3. Use AWS Budgets (already configured in AFT) for actual cost alerts
4. Monitor via Cost Explorer regularly

---

## OU Target IDs Reference

| OU Name | ID | Recommended SCP |
|---------|-----|-----------------|
| LearnMck | `ou-hn55-ambq41wc` | ✅ Yes |
| Sandbox | `ou-hn55-8v2p3o33` | ✅ Yes |
| Batch14 | `ou-hn55-97mt9432` | ✅ Yes |
| Batch15 | `ou-hn55-si8zml39` | ✅ Yes |
| AFT-Lab-Rajesh | `ou-hn55-j1275av7` | ⚠️ Maybe |
| Security | `ou-hn55-nk6je9rf` | ❌ No |
| SuspendedAccount | `ou-hn55-0vban4ke` | ❌ No |

---

## Support

For questions or to customize the SCP, see:
- AWS SCPs Documentation: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html
- Policy Simulator: https://policysim.aws.amazon.com/

