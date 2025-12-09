# 🚀 Bulk Account Creation Guide

## Overview

Create **multiple AWS accounts at once** using GitHub Actions workflows. Perfect for creating accounts for student batches, team members, or multi-environment setups.

---

## 📋 Bulk Account Creation Workflow

**Workflow:** `create-bulk-accounts-csv.yml` (CSV Format)

**Perfect for:** 
- Quick bulk creation
- Copying from spreadsheets (Excel, Google Sheets)
- Student batch provisioning
- Team sandbox creation

---

## 🎯 How to Use

### Step 1: Go to the Workflow
```
https://github.com/ravishmck/learn-terraform-aft-account-request/actions/workflows/create-bulk-accounts-csv.yml
```

### Step 2: Click "Run workflow"

### Step 3: Enter Accounts in CSV Format

**Format:** `AccountName,Email,OU,Environment`

**Example:**
```csv
Student1Account,student1+aws@example.com,Batch14,Development
Student2Account,student2+aws@example.com,Batch14,Development
Student3Account,student3+aws@example.com,Batch14,Development
DevAccount,dev+aws@example.com,Sandbox,Development
TestAccount,test+aws@example.com,Sandbox,Testing
ProdAccount,prod+aws@example.com,LearnMck,Production
```

**Available OUs:**
- `LearnMck`
- `Sandbox`
- `Batch14`
- `Batch15`
- `AFT-Lab-Rajesh`
- `Security`

**Available Environments:**
- `Development`
- `Testing`
- `Staging`
- `Production`

### Step 4: Click "Run workflow"

✅ **Done!** All accounts will be created automatically.

---

## 📊 Real-World Examples

### Example 1: Create Accounts for a Training Batch

**Scenario:** 20 students need AWS accounts for Batch 15

**CSV Input:**
```csv
Batch15Student01,student01+batch15@training.com,Batch15,Development
Batch15Student02,student02+batch15@training.com,Batch15,Development
Batch15Student03,student03+batch15@training.com,Batch15,Development
...
Batch15Student20,student20+batch15@training.com,Batch15,Development
```

**Result:** 20 accounts created in ~20 minutes, all in Batch15 OU

---

### Example 2: Multi-Environment Setup

**Scenario:** Create Dev, Test, Staging, Prod accounts for a project

**CSV Input:**
```csv
ProjectX-Dev,projectx+dev@company.com,Sandbox,Development
ProjectX-Test,projectx+test@company.com,Sandbox,Testing
ProjectX-Staging,projectx+staging@company.com,LearnMck,Staging
ProjectX-Prod,projectx+prod@company.com,LearnMck,Production
```

**Result:** 4 accounts across 2 OUs

---

### Example 3: Team Sandbox Accounts

**Scenario:** Give each team member a personal sandbox

**CSV Input:**
```csv
Ravish-Sandbox,ravish+sandbox@company.com,Sandbox,Development
John-Sandbox,john+sandbox@company.com,Sandbox,Development
Sarah-Sandbox,sarah+sandbox@company.com,Sandbox,Development
Mike-Sandbox,mike+sandbox@company.com,Sandbox,Development
```

---

## 💡 Pro Tips

### 1. Use Email Aliases
Gmail supports `+` aliases:
```
ravish.snkhyn+student1@gmail.com
ravish.snkhyn+student2@gmail.com
ravish.snkhyn+student3@gmail.com
```
All emails go to the same inbox!

### 2. Generate from Spreadsheet
1. Create accounts in Excel/Google Sheets
2. Format as: `Name,Email,OU,Environment`
3. Copy and paste into workflow
4. ✅ Done!

### 3. Batch Naming Convention
Use consistent naming:
```
Batch14-Student01
Batch14-Student02
Batch14-Student03
```

Makes it easier to manage later!

### 4. Limit per Run
**Recommendation:** Create **10-15 accounts per run**
- Easier to monitor
- Less chance of hitting rate limits
- Better error handling

---

## ⏱️ Timeline

For **10 accounts**:

| Time | Event |
|------|-------|
| 0 min | Workflow triggered ✅ |
| +2 min | CodePipeline starts |
| +5 min | All requests in DynamoDB |
| +10 min | First accounts appear in Organizations |
| +20 min | All 10 accounts ACTIVE ✅ |

**Note:** Accounts are created in parallel, so 10 accounts takes roughly the same time as 1 account!

---

## 📧 Email Notifications

Each account gets:
- ✅ Budget alerts at 80%, 90%, 100% ($160, $180, $200)
- ✅ Forecasted spending alerts
- ✅ SSO access confirmation

**Email Template:**
```
To: ravish.snkhyn@gmail.com
Subject: AWS Budgets: Budget Alert for monthly-budget-200-usd

Your budget "monthly-budget-200-usd" has exceeded 80% of $200.00
Current spending: $160.50
```

---

## 🔍 Monitoring Bulk Creation

### Via GitHub Actions
1. Go to the workflow run
2. Check "Summary" tab for all account details
3. ✅ Green checkmark = Successfully pushed

### Via AWS Console

**DynamoDB:**
```
https://ap-south-1.console.aws.amazon.com/dynamodbv2/home?region=ap-south-1#table?name=aft-request
```
- All account requests appear here first

**Organizations:**
```
https://console.aws.amazon.com/organizations/v2/home/accounts
```
- Final destination - accounts appear here when ACTIVE

**CodePipeline:**
```
https://ap-south-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/ct-aft-account-request/view
```
- Monitor the terraform apply process

---

## ❌ Troubleshooting

### Issue: "Push failed" Error

**Cause:** Multiple users running workflows simultaneously

**Solution:** Workflow auto-retries 5 times with pull-rebase

**Manual fix:** Re-run the workflow

---

### Issue: "Invalid JSON" Error

**Cause:** Syntax error in JSON input

**Solution:** Validate JSON at https://jsonlint.com/

**For CSV:** Use CSV format workflow instead!

---

### Issue: Account limit reached

**Error:** `AWS Control Tower cannot create an account because you have reached the limit`

**Solution:**
1. Check current limit: `aws organizations list-accounts --query 'length(Accounts)'`
2. Remove suspended accounts or request quota increase
3. See: `docs/SERVICE-QUOTA-INCREASE.md`

---

### Issue: Duplicate email

**Error:** Email address already used

**Solution:** Each account needs a **unique** email

**Tip:** Use `+` aliases:
```
user+account1@gmail.com
user+account2@gmail.com
```

---

## 🔐 Security & Cost Control

### Automatic Budget Enforcement
- ✅ Every account gets $200/month budget
- ✅ Alerts at 80%, 90%, 100%
- ✅ No manual configuration needed

### Optional SCP Protection
Apply SCP to prevent expensive services:
```bash
bash scripts/apply-scp.sh
```

Choose the OU (Batch14, Batch15, etc.) to protect all accounts in that OU.

---

## 📊 Comparison: Single vs Bulk

| Feature | Single Account | Bulk CSV |
|---------|---------------|----------|
| **Accounts per run** | 1 | Unlimited |
| **Data format** | Form fields | CSV |
| **Easy to use** | ✅✅✅ | ✅✅✅ |
| **Copy from Excel** | ❌ | ✅✅✅ |
| **Time to create 10 accounts** | ~200 min (one at a time) | ~20 min (parallel) |
| **Best for** | Single quick tests | Batches, teams, multi-environment |

---

## 🎯 Quick Reference

### Workflow URL
```
https://github.com/ravishmck/learn-terraform-aft-account-request/actions/workflows/create-bulk-accounts-csv.yml
```

### CSV Format
```
Name,Email,OU,Environment
```

### Example
```csv
Student1,student1@example.com,Batch14,Development
Student2,student2@example.com,Batch14,Development
```

### Available OUs
```
LearnMck, Sandbox, Batch14, Batch15, AFT-Lab-Rajesh, Security
```

### Available Environments
```
Development, Testing, Staging, Production
```

---

## 📞 Need Help?

1. **Check workflow runs:** GitHub Actions tab
2. **View DynamoDB:** See if requests were created
3. **Check Organizations:** See if accounts are ACTIVE
4. **Review logs:** Click on failed workflow step

---

**Ready to create accounts in bulk? Just copy your data into CSV format and run the workflow!** 🚀

