# 🔐 Setup AWS Credentials for Workflow Monitoring

This guide explains how to enable automated monitoring in GitHub Actions workflows.

---

## 🎯 What This Enables

With AWS credentials configured as GitHub secrets, your workflows will:

✅ **Monitor account creation** until complete  
✅ **Verify account is ACTIVE** in Organizations  
✅ **Confirm decommission** is complete  
✅ **Report status** in real-time  
✅ **No manual checking** needed!

**Without credentials:** Workflows stop after committing code  
**With credentials:** Workflows monitor until completion ⭐

---

## 📋 Prerequisites

You need AWS credentials with these permissions:
- `organizations:ListAccounts` 
- `dynamodb:GetItem`
- `codepipeline:GetPipelineState`
- `codepipeline:ListPipelineExecutions`

**Recommended:** Use the `ct-mgmt` profile credentials (Read-only access is sufficient)

---

## 🔧 Step-by-Step Setup

### **Step 1: Get Your AWS Credentials**

```bash
# View your credentials
cat ~/.aws/credentials
```

Look for the `[ct-mgmt]` section:
```ini
[ct-mgmt]
aws_access_key_id = AKIAXXXXXXXXXXXX
aws_secret_access_key = your-secret-access-key-here
```

---

### **Step 2: Add Secrets to GitHub**

#### **Go to Repository Settings:**
https://github.com/ravishmck/learn-terraform-aft-account-request/settings/secrets/actions

#### **Click:** "New repository secret"

#### **Add Secret 1:**
```
Name:  AWS_ACCESS_KEY_ID
Value: <your-access-key-from-credentials-file>
```
Click "Add secret"

#### **Add Secret 2:**
```
Name:  AWS_SECRET_ACCESS_KEY
Value: <your-secret-key-from-credentials-file>
```
Click "Add secret"

---

## ✅ Verify Setup

After adding secrets, your secrets page should show:
```
AWS_ACCESS_KEY_ID           Updated X minutes ago
AWS_SECRET_ACCESS_KEY       Updated X minutes ago
```

---

## 🎬 How It Works

### **Create Account Workflow:**

```
Without Credentials:
├─ Create Terraform code
├─ Commit & push
└─ ✅ Done (you check manually)

With Credentials:
├─ Create Terraform code
├─ Commit & push
├─ Wait 2 minutes (EventBridge)
├─ Monitor CodePipeline
├─ Check DynamoDB
├─ Check Organizations
└─ ✅ Done (Account ACTIVE confirmed!)
```

### **Close Account Workflow:**

```
Without Credentials:
├─ Comment out Terraform code
├─ Commit & push
└─ ✅ Done (you check manually)

With Credentials:
├─ Comment out Terraform code
├─ Commit & push
├─ Wait 2 minutes (EventBridge)
├─ Monitor CodePipeline
├─ Check DynamoDB removal
└─ ✅ Done (Removal confirmed!)
```

---

## 📊 Monitoring Details

### **What Gets Monitored:**

| Check | What It Does | Frequency |
|-------|--------------|-----------|
| **CodePipeline** | Checks if Terraform is running | Every 1 min |
| **DynamoDB** | Verifies account request entry | Every 1 min |
| **Organizations** | Confirms account is ACTIVE | Every 1 min |

### **Timeouts:**

- **Create Account:** 30 minutes max
- **Close Account:** 10 minutes max

If timeout reached, workflow suggests manual checking.

---

## 🔒 Security Best Practices

### **✅ DO:**
- Use read-only credentials when possible
- Rotate credentials regularly
- Use IAM user with minimal permissions
- Keep credentials as GitHub secrets (never in code)

### **❌ DON'T:**
- Use root account credentials
- Share credentials
- Commit credentials to git
- Use credentials with write permissions

---

## 🎯 IAM Policy (Minimal Permissions)

If you want to create a dedicated IAM user for monitoring:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "organizations:ListAccounts",
        "organizations:DescribeAccount",
        "dynamodb:GetItem",
        "dynamodb:Query",
        "codepipeline:GetPipelineState",
        "codepipeline:ListPipelineExecutions"
      ],
      "Resource": "*"
    }
  ]
}
```

**Name the policy:** `AFT-Workflow-Monitoring-ReadOnly`

---

## 🆘 Troubleshooting

### **"AWS credentials not configured"**
**Solution:** Add the two secrets in GitHub as described above

### **"Access Denied" errors in workflow**
**Solution:** The credentials need these permissions:
- `organizations:ListAccounts`
- `dynamodb:GetItem`
- `codepipeline:GetPipelineState`

### **Workflow still not monitoring**
**Solution:** 
1. Check secrets are named exactly: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
2. Re-run the workflow (it needs to start fresh after adding secrets)

### **Credentials expired**
**Solution:** If using temporary credentials, they'll expire. Use permanent IAM user credentials instead.

---

## 📝 Alternative: Skip Monitoring

If you prefer not to add AWS credentials, the workflows will:
- ✅ Still create/close accounts
- ✅ Commit Terraform changes
- ⚠️ Skip automated monitoring
- 💡 Show you manual checking links

**This is perfectly fine!** Monitoring is optional.

---

## 🔗 Quick Links

| What | Link |
|------|------|
| **Add Secrets** | https://github.com/ravishmck/learn-terraform-aft-account-request/settings/secrets/actions |
| **View Workflows** | https://github.com/ravishmck/learn-terraform-aft-account-request/actions |
| **AWS IAM Console** | https://console.aws.amazon.com/iam/home#/users |

---

## ✅ Summary

**To enable full automation:**
1. Copy AWS credentials from `~/.aws/credentials`
2. Add as GitHub secrets (2 secrets)
3. Run workflows - they'll monitor automatically!

**Result:** 
- Create accounts → Wait → See "ACTIVE" status ✅
- Close accounts → Wait → See "Removed" status ✅
- No manual checking needed!

---

**Last Updated:** December 8, 2025  
**Required Secrets:** 2 (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)  
**Optional:** Yes (workflows work without credentials, just no monitoring)

