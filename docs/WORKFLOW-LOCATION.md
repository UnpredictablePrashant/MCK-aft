# 🚀 Workflow Location & Quick Start

## ⚡ **Create New AWS Account**

### **Direct Link (Click Here!):**
👉 **https://github.com/ravishmck/learn-terraform-aft-account-request/actions**

---

## 📋 **3-Step Process:**

### Step 1: Go to Workflow
Click the link above or navigate to:
```
https://github.com/ravishmck/learn-terraform-aft-account-request/actions
```

### Step 2: Run Workflow
1. Click **"🚀 Create AWS Account Request"** (left sidebar)
2. Click **"Run workflow"** (green button)
3. Fill the 4-field form:
   - Account Name: `DevAccount`
   - Account Email: `unique@email.com` (must be unique!)
   - OU: `LearnMck`
   - Environment: `Development`
4. Click **"Run workflow"**

### Step 3: Wait
⏰ **~20 minutes** → Account appears in AWS Organizations!

---

## ❓ **Why This Location?**

**Previous Issue:** The workflow was in the main `MCK-aft` repo, which caused permission errors when trying to push to the account-request submodule.

**Solution:** Moved the workflow directly to the `learn-terraform-aft-account-request` repository where it has permission to commit and push.

---

## 🔧 **Technical Details**

### **Repository Structure:**
```
ravishmck/learn-terraform-aft-account-request
├── .github/workflows/
│   └── create-account.yml  ← WORKFLOW IS HERE
└── terraform/
    └── main.tf  ← Account requests go here
```

### **What the Workflow Does:**
1. ✅ Creates Terraform module for your account
2. ✅ Commits to `terraform/main.tf`
3. ✅ Pushes to GitHub
4. ✅ EventBridge detects change (2 min)
5. ✅ CodePipeline runs Terraform
6. ✅ DynamoDB entry created
7. ✅ AFT provisions account
8. ✅ Account appears in Organizations!

---

## 📊 **Monitor Progress**

| What | Link |
|------|------|
| **Workflow Runs** | https://github.com/ravishmck/learn-terraform-aft-account-request/actions |
| **CodePipeline** | https://ap-south-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/ct-aft-account-request/view |
| **Organizations** | https://console.aws.amazon.com/organizations/v2/home/accounts |
| **Step Functions** | https://ap-south-1.console.aws.amazon.com/states/home?region=ap-south-1 |

---

## 🆘 **Common Issues**

### ❌ **"Workflow not found"**
**Solution:** Make sure you're at:  
https://github.com/ravishmck/learn-terraform-aft-account-request/actions  
(NOT the main MCK-aft repo)

### ❌ **"Permission denied"**
**Solution:** This shouldn't happen anymore! The workflow runs in its own repo now.

### ❌ **"Email already used"**
**Solution:** Use a unique email. Try Gmail's `+` trick:
- `email+dev@gmail.com`
- `email+test@gmail.com`
- `email+prod@gmail.com`

---

## 📚 **More Documentation**

- [Full User Guide](./HOW-TO-CREATE-ACCOUNTS.md)
- [Visual Guide](./WORKFLOW-VISUAL-GUIDE.md)
- [Troubleshooting](./TROUBLESHOOTING.md)
- [Main README](../README.md)

---

## ✅ **Summary**

| Item | Status |
|------|--------|
| **Workflow Location** | ✅ learn-terraform-aft-account-request repo |
| **Permission Issues** | ✅ Fixed |
| **Auto-Trigger** | ✅ Working (EventBridge) |
| **Documentation** | ✅ Updated |
| **Ready to Use** | ✅ YES! |

---

**Last Updated:** December 8, 2025  
**Workflow Path:** `.github/workflows/create-account.yml`  
**Repository:** https://github.com/ravishmck/learn-terraform-aft-account-request

