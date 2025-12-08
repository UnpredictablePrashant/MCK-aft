# 🗑️ How to Close/Decommission AWS Accounts

This guide explains how to safely close or decommission AWS accounts created by AFT.

---

## ⚡ Quick Start

### **1. Go to Workflow**
👉 https://github.com/ravishmck/learn-terraform-aft-account-request/actions

### **2. Run "🗑️ Close/Decommission AWS Account"**

### **3. Fill the Form**
- **Account ID**: The 12-digit AWS account ID
- **Account Email**: Email used when creating the account
- **Action Type**: Choose what you want to do
- **Reason**: Why you're closing this account
- **Confirmation**: Type `CONFIRM` (required!)

---

## 🎯 Action Types Explained

### **Option 1: Remove from Terraform (soft delete)** ⭐ Recommended First Step

**What it does:**
- Comments out the account module in Terraform
- Creates a decommission log
- Terraform removes the account from DynamoDB
- Account stays in AWS Organizations (still active)

**When to use:**
- You want to stop AFT management
- Account should remain active
- Safest option (easily reversible)

**Next steps:**
- Account removed from AFT tracking
- EventBridge triggers Terraform (~2 min)
- Account entry removed from DynamoDB

---

### **Option 2: Close Account (AWS suspension)**

**What it does:**
- Creates decommission log
- Provides instructions for AWS Console closure

**Manual steps required:**
1. Go to AWS Organizations Console
2. Find the account
3. Click "Close account"
4. Confirm closure

**Important:**
- Account suspended immediately
- 90-day waiting period before permanent deletion
- Can be restored within 90 days
- All resources must be cleaned up first

---

### **Option 3: Remove from Organization**

**What it does:**
- Creates decommission log
- Provides instructions for removal

**Manual steps required:**
1. Go to AWS Organizations Console
2. Find the account
3. Click "Remove from organization"
4. Confirm removal

**Important:**
- Account becomes standalone (not deleted)
- Billing transfers to removed account
- Can be re-invited to organization
- Account remains active

---

## 📋 Step-by-Step Example

### **Scenario:** Close a test account that's no longer needed

### **Step 1: Gather Information**
```
Account ID:    123456789012
Account Email: test-account@example.com
Reason:        Test completed, no longer needed
```

### **Step 2: Run Workflow**
1. Go to: https://github.com/ravishmck/learn-terraform-aft-account-request/actions
2. Click: "🗑️ Close/Decommission AWS Account"
3. Click: "Run workflow"

### **Step 3: Fill Form**
```
Account ID:        123456789012
Account Email:     test-account@example.com
Action Type:       Remove from Terraform (soft delete)
Reason:            Test completed, no longer needed
Confirmation:      CONFIRM
```

### **Step 4: Click "Run workflow"**

### **Step 5: Review Results**
- Workflow creates decommission log
- Terraform removes from AFT (~2 min)
- Check decommission log for details

---

## 🔄 Recommended Closure Process

### **Best Practice: Two-Step Closure**

**Step 1: Remove from AFT Management**
```
Action: "Remove from Terraform (soft delete)"
Result: AFT stops managing the account
```

**Wait 24-48 hours** (verify everything works)

**Step 2: Close the Account**
```
Action: "Close Account (AWS suspension)"
Result: Account suspended in AWS
```

This gives you time to ensure no services depend on the account.

---

## 📊 What Happens After Closure

### **Immediate (0-2 minutes):**
- Workflow commits changes
- Decommission log created

### **Within 2 minutes:**
- EventBridge triggers pipeline
- Terraform applies changes
- Account removed from DynamoDB

### **After Manual Closure (if selected):**
- Account suspended in AWS
- 90-day waiting period starts
- Resources should be cleaned first

---

## 🔍 Finding Account Information

### **Find Account ID:**
```bash
# In AWS CLI
aws organizations list-accounts \
  --query "Accounts[?Email=='account@example.com'].Id" \
  --output text
```

### **Find Account Email:**
Check the Terraform code:
```bash
grep -r "AccountEmail" learn-terraform-aft-account-request/terraform/
```

Or check AWS Organizations Console:
https://console.aws.amazon.com/organizations/v2/home/accounts

---

## 📄 Decommission Logs

After running the workflow, a log file is created:

**Location:** `decommissioned/account-{ACCOUNT_ID}.md`

**Contents:**
- Account details
- Action taken
- Timestamp
- Who requested it
- Next steps
- Restoration instructions

**View logs:**
https://github.com/ravishmck/learn-terraform-aft-account-request/tree/main/decommissioned

---

## 🔄 Restoring a Closed Account

### **If you used "Remove from Terraform":**

1. Go to: `terraform/main.tf`
2. Find the commented-out module block
3. Uncomment it (remove the `#` symbols)
4. Commit and push
5. Wait ~2 minutes for Terraform to apply
6. Account restored in AFT!

### **If you closed in AWS:**

Within the 90-day period:
1. Contact AWS Support
2. Request account restoration
3. Re-add to AFT if needed

---

## ⚠️ Important Notes

### **Before Closing an Account:**

✅ **DO:**
- Clean up all resources (EC2, RDS, etc.)
- Download any needed data
- Close outstanding bills
- Document the closure reason
- Notify affected teams

❌ **DON'T:**
- Close accounts with active resources
- Close without documenting
- Close without team notification
- Rush the closure process

### **AWS Account Closure Facts:**

- Suspended for 90 days before permanent deletion
- Cannot be reopened after 90 days
- All data will be permanently deleted
- Account ID cannot be reused
- Outstanding charges still apply

---

## 🆘 Troubleshooting

### **"Account not found in Terraform"**
**Solution:** The account email doesn't match. Check the exact email used.

### **"Confirmation not provided"**
**Solution:** You must type `CONFIRM` (all caps) in the confirmation field.

### **"Push failed"**
**Solution:** The workflow includes retry logic. It should succeed automatically.

### **"Can't close account in AWS Console"**
**Possible causes:**
- Account has active resources
- Outstanding bills
- Account is management account
- Insufficient permissions

---

## 📚 Additional Resources

- [AWS Account Closure Documentation](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html)
- [AFT Documentation](https://docs.aws.amazon.com/controltower/latest/userguide/aft-overview.html)
- [Create Accounts Guide](./HOW-TO-CREATE-ACCOUNTS.md)

---

## 🔗 Quick Links

| What | Link |
|------|------|
| **Close Account Workflow** | https://github.com/ravishmck/learn-terraform-aft-account-request/actions |
| **View Decommission Logs** | https://github.com/ravishmck/learn-terraform-aft-account-request/tree/main/decommissioned |
| **AWS Organizations** | https://console.aws.amazon.com/organizations/v2/home/accounts |
| **Create Accounts** | [HOW-TO-CREATE-ACCOUNTS.md](./HOW-TO-CREATE-ACCOUNTS.md) |

---

**Last Updated:** December 8, 2025  
**Workflow:** `.github/workflows/close-account.yml`  
**Repository:** https://github.com/ravishmck/learn-terraform-aft-account-request

