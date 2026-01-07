# 📈 Service Quota Increase Guide

This guide explains how to request AWS service quota increases, particularly for account limits.

---

## 🎯 Overview

AWS Organizations has default limits on:

| Quota | Default | Can Increase? |
|-------|---------|---------------|
| Accounts per organization | 10 | ✅ Yes |
| OUs per organization | 1000 | ✅ Yes |
| Policies per organization | 1000 | ✅ Yes |
| Nested OUs depth | 5 | ❌ No |

---

## 📊 Check Current Limits

### Via AWS Console

1. Go to **Service Quotas**:
   ```
   https://console.aws.amazon.com/servicequotas/home
   ```

2. Select **AWS Organizations**

3. View current quotas and usage

### Via AWS CLI

```bash
# Get account limit
aws service-quotas get-service-quota \
  --service-code organizations \
  --quota-code L-29A0C5DF \
  --query 'Quota.[QuotaName,Value]' \
  --output text

# List all Organizations quotas
aws service-quotas list-service-quotas \
  --service-code organizations \
  --query 'Quotas[*].[QuotaName,Value]' \
  --output table
```

### Count Current Accounts

```bash
# Count total accounts
aws organizations list-accounts --query 'length(Accounts)'

# List all accounts with status
aws organizations list-accounts \
  --query 'Accounts[*].[Name,Status,Id]' \
  --output table
```

---

## 🚀 Request Quota Increase

### Method 1: AWS Console (Easiest)

1. **Go to Service Quotas:**
   ```
   https://console.aws.amazon.com/servicequotas/home/services/organizations/quotas
   ```

2. **Find "Accounts" quota**

3. **Click "Request quota increase"**

4. **Enter desired value** (e.g., 50, 100, 500)

5. **Submit request**

### Method 2: AWS CLI

```bash
# Request increase to 50 accounts
aws service-quotas request-service-quota-increase \
  --service-code organizations \
  --quota-code L-29A0C5DF \
  --desired-value 50
```

### Method 3: AWS Support Case

1. **Go to AWS Support Center:**
   ```
   https://console.aws.amazon.com/support/home
   ```

2. **Create case:**
   - Type: Service limit increase
   - Service: Organizations
   - Request: Account limit increase

3. **Provide justification:**
   - Number of accounts needed
   - Use case (training, multi-environment, etc.)
   - Timeline

---

## 📋 Request Template

### For Training/Education

```
Subject: AWS Organizations Account Limit Increase Request

Current Limit: 10 accounts
Requested Limit: 100 accounts

Use Case:
We are an educational organization running AWS training programs. 
Each student batch requires individual AWS accounts for hands-on labs.

Justification:
- Batch 14: 25 students
- Batch 15: 25 students  
- Buffer for instructors and testing: 10 accounts
- Future batches planned

We use AWS Control Tower and AFT for automated account 
provisioning with $200 budget limits and SCPs to control costs.

Timeline: Within 1 week

Thank you.
```

### For Multi-Environment Development

```
Subject: AWS Organizations Account Limit Increase Request

Current Limit: 10 accounts
Requested Limit: 50 accounts

Use Case:
We have multiple projects requiring isolated AWS environments 
(Dev, Test, Staging, Production) for each.

Justification:
- Project A: 4 environments (Dev, Test, Stage, Prod)
- Project B: 4 environments
- Project C: 4 environments
- Shared services accounts: 5
- Growth buffer: 10 accounts

All accounts are managed via AWS Control Tower with 
automated governance and cost controls.

Timeline: Within 1 week

Thank you.
```

---

## ⏱️ Timeline

| Request Type | Typical Response Time |
|--------------|----------------------|
| Small increase (10 → 25) | 1-3 business days |
| Medium increase (10 → 100) | 3-5 business days |
| Large increase (10 → 500+) | 5-10 business days |

**Tips for faster approval:**
- ✅ Provide clear justification
- ✅ Explain cost controls in place
- ✅ Mention Control Tower usage
- ✅ Specify realistic numbers

---

## 📊 Monitor Request Status

### Via Console

1. Go to **Service Quotas**
2. Click **Quota request history**
3. View status of your requests

### Via CLI

```bash
# List all quota requests
aws service-quotas list-requested-service-quota-change-history \
  --service-code organizations \
  --query 'RequestedQuotas[*].[QuotaName,DesiredValue,Status,Created]' \
  --output table
```

**Status Values:**
- `PENDING` - Request submitted, under review
- `CASE_OPENED` - AWS Support reviewing
- `APPROVED` - Increase granted
- `DENIED` - Request denied
- `CASE_CLOSED` - Case resolved (check result)

---

## 🔄 After Approval

### Verify New Limit

```bash
aws service-quotas get-service-quota \
  --service-code organizations \
  --quota-code L-29A0C5DF \
  --query 'Quota.Value'
```

### No Action Needed

- ✅ Limit is automatically applied
- ✅ AFT will work with new limit
- ✅ No restart required

---

## 🚨 What If Denied?

### Common Reasons for Denial

1. **New account** - AWS may limit new organizations
2. **Payment issues** - Verify billing is current
3. **Previous abuse** - Account may be flagged
4. **Unreasonable request** - Asking for too much too fast

### Appeal Process

1. **Respond to the case** with more details
2. **Start smaller** - request 25 instead of 500
3. **Demonstrate usage** - show you're using current accounts
4. **Contact AWS account team** if you have one

---

## 💡 Best Practices

### Plan Ahead

- Request increases **before** you hit limits
- Buffer of 10-20% above projected needs
- Quarterly review of quota usage

### Clean Up Unused Accounts

Before requesting increase:

```bash
# Find suspended/unused accounts
aws organizations list-accounts \
  --query "Accounts[?Status!='ACTIVE'].[Name,Status,Id]" \
  --output table
```

Close accounts you no longer need to free up quota.

### Use OUs Effectively

Group accounts to stay organized:
```
Root
├── LearnMck (production learning)
├── Sandbox (experimentation)
├── Batch14 (student group)
├── Batch15 (student group)
├── SuspendedAccount (accounts to close)
└── Security (security tooling)
```

---

## 📚 Other Common Quotas

### CodeBuild Quotas

```bash
aws service-quotas list-service-quotas \
  --service-code codebuild \
  --query 'Quotas[*].[QuotaName,Value]' \
  --output table
```

### Lambda Quotas

```bash
aws service-quotas list-service-quotas \
  --service-code lambda \
  --query 'Quotas[*].[QuotaName,Value]' \
  --output table
```

### DynamoDB Quotas

```bash
aws service-quotas list-service-quotas \
  --service-code dynamodb \
  --query 'Quotas[*].[QuotaName,Value]' \
  --output table
```

---

## 🔗 Useful Links

- **Service Quotas Console:** https://console.aws.amazon.com/servicequotas
- **AWS Support Center:** https://console.aws.amazon.com/support/home
- **AWS Organizations Quotas Doc:** https://docs.aws.amazon.com/organizations/latest/userguide/orgs_reference_limits.html

---

## 📋 Quick Reference

### Quota Codes

| Quota | Code |
|-------|------|
| Accounts per organization | `L-29A0C5DF` |
| OUs per organization | `L-5F3E0B50` |
| Policies per organization | `L-9CE55C77` |

### CLI Commands

```bash
# Check current account limit
aws service-quotas get-service-quota \
  --service-code organizations \
  --quota-code L-29A0C5DF

# Request increase
aws service-quotas request-service-quota-increase \
  --service-code organizations \
  --quota-code L-29A0C5DF \
  --desired-value NEW_LIMIT

# Check request status
aws service-quotas list-requested-service-quota-change-history \
  --service-code organizations
```

---

**Last Updated:** January 2026  
**Related:** [Troubleshooting](./TROUBLESHOOTING.md) | [How to Create Accounts](./HOW-TO-CREATE-ACCOUNTS.md)

