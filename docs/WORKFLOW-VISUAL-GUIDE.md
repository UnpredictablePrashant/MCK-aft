# 🎯 Visual Guide: GitHub Actions Workflow

This guide shows you exactly what the workflow looks like and how to use it.

---

## 📱 Step-by-Step Screenshots Guide

### Step 1: Navigate to GitHub Actions

**URL:** `https://github.com/UnpredictablePrashant/MCK-aft/actions`

You'll see:
```
┌─────────────────────────────────────────────────┐
│  Actions                                        │
├─────────────────────────────────────────────────┤
│  All workflows                                  │
│  ├─ 🚀 Create New AWS Account         [●]      │
│  └─ (other workflows...)                        │
└─────────────────────────────────────────────────┘
```

---

### Step 2: Click "Run workflow"

You'll see this form:

```
┌────────────────────────────────────────────────────────┐
│  Run workflow                                          │
├────────────────────────────────────────────────────────┤
│                                                        │
│  Branch: main                          [▼]            │
│                                                        │
│  📝 Account Name                                       │
│  ┌──────────────────────────────────────────┐        │
│  │ DevAccount                               │        │
│  └──────────────────────────────────────────┘        │
│  Account Name (e.g., DevAccount)                      │
│                                                        │
│  📧 Unique Account Email                              │
│  ┌──────────────────────────────────────────┐        │
│  │ myproject+dev@gmail.com                  │        │
│  └──────────────────────────────────────────┘        │
│  Account Email (must be unique)                       │
│                                                        │
│  🏢 Organizational Unit                               │
│  ┌──────────────────────────────────────────┐        │
│  │ LearnMck                        [▼]      │        │
│  └──────────────────────────────────────────┘        │
│  • LearnMck                                           │
│  • AFTLearn                                           │
│                                                        │
│  🌍 Environment Type                                  │
│  ┌──────────────────────────────────────────┐        │
│  │ Development                     [▼]      │        │
│  └──────────────────────────────────────────┘        │
│  • Development                                        │
│  • Testing                                            │
│  • Staging                                            │
│  • Production                                         │
│                                                        │
│  [ Run workflow ]                                     │
│                                                        │
└────────────────────────────────────────────────────────┘
```

---

### Step 3: Workflow Runs!

After clicking "Run workflow", you'll see:

```
┌────────────────────────────────────────────────────────┐
│  🚀 Create New AWS Account                             │
├────────────────────────────────────────────────────────┤
│  ✅ request-account                                    │
│      ├─ 📥 Checkout Repository              ✓         │
│      ├─ 🔧 Configure Git                    ✓         │
│      ├─ 📦 Update Account Request Submodule ✓         │
│      ├─ 📝 Create Account Request Module    ✓         │
│      ├─ 💾 Commit to Account Request Repo   ✓         │
│      ├─ 🔄 Update Main Repo Submodule       ✓         │
│      ├─ 🎉 Success!                         ✓         │
│      └─ 📊 Create Workflow Summary          ✓         │
│                                                        │
│  Duration: 23 seconds                                  │
└────────────────────────────────────────────────────────┘
```

---

### Step 4: Workflow Summary

Click on the workflow run to see a beautiful summary:

```
┌────────────────────────────────────────────────────────┐
│  🎉 AWS Account Request Submitted!                     │
├────────────────────────────────────────────────────────┤
│                                                        │
│  📋 Account Information                                │
│  ┌──────────────────────┬─────────────────────────┐  │
│  │ Account Name         │ DevAccount              │  │
│  │ Email                │ myproject+dev@gmail.com │  │
│  │ Organizational Unit  │ LearnMck                │  │
│  │ Environment          │ Development             │  │
│  │ Requested By         │ @ravishmck              │  │
│  └──────────────────────┴─────────────────────────┘  │
│                                                        │
│  ⏰ What Happens Next?                                 │
│  ┌────────────────────────────────────────────────┐  │
│  │  GitHub Push → EventBridge → CodePipeline      │  │
│  │       ↓              ↓              ↓          │  │
│  │   2 minutes      Terraform      DynamoDB       │  │
│  │                      ↓              ↓          │  │
│  │                  Lambda         SQS Queue      │  │
│  │                      ↓              ↓          │  │
│  │              Account Processor  Service Cat    │  │
│  │                                    ↓          │  │
│  │                          AWS Organizations     │  │
│  │                                    ↓          │  │
│  │                         ✅ Account Ready!      │  │
│  └────────────────────────────────────────────────┘  │
│                                                        │
│  Total Time: ~20 minutes                               │
│                                                        │
│  📊 Monitor Progress                                   │
│  • CodePipeline → [View]                              │
│  • Step Functions → [View]                            │
│  • AWS Organizations → [View]                         │
│                                                        │
└────────────────────────────────────────────────────────┘
```

---

## 🎬 Complete Flow Animation

```
You (GitHub UI)
    │
    │ Click "Run workflow"
    │ Fill simple form
    │
    ↓
GitHub Actions Workflow
    │
    │ Checkout repo + submodules
    │ Create Terraform module
    │ Commit to account-request repo
    │ Push changes
    │
    ↓
GitHub Repository (account-request)
    │
    │ New commit detected
    │
    ↓
EventBridge (AWS - every 2 minutes)
    │
    │ Detects GitHub change
    │ Triggers pipeline
    │
    ↓
CodePipeline
    │
    │ Source: Pull from GitHub
    │ Build: Run Terraform apply
    │
    ↓
Terraform
    │
    │ Creates/Updates DynamoDB entry
    │
    ↓
DynamoDB Stream
    │
    │ INSERT event detected
    │
    ↓
Lambda: action-trigger
    │
    │ Validates account request
    │ Sends message to SQS
    │
    ↓
SQS Queue
    │
    │ Holds account request
    │
    ↓
Lambda: account-processor (every 5 min)
    │
    │ Processes SQS message
    │ Calls Service Catalog
    │
    ↓
Service Catalog
    │
    │ Invokes Control Tower
    │ Creates AWS account
    │ Sets up baseline
    │
    ↓
AWS Organizations
    │
    │ New account appears!
    │ Status: ACTIVE
    │
    ↓
You (AWS Console)
    │
    │ Account ready to use! ✅
    │ Access via SSO
    │
    🎉
```

---

## 🎨 Form Examples

### Example 1: Development Account

```yaml
Account Name:    MyApp-Dev
Account Email:   ravish.snkhyn+myapp-dev@gmail.com
OU:             LearnMck
Environment:    Development
```

**Result:** Development account for "MyApp" project

---

### Example 2: Production Account

```yaml
Account Name:    MyApp-Production
Account Email:   ravish.snkhyn+myapp-prod@gmail.com
OU:             LearnMck
Environment:    Production
```

**Result:** Production account for "MyApp" project

---

### Example 3: Testing Environment

```yaml
Account Name:    QA-Environment
Account Email:   ravish.snkhyn+qa-test@gmail.com
OU:             LearnMck
Environment:    Testing
```

**Result:** QA/Testing account

---

## 🎯 What You'll See in AWS

### After ~5 minutes:

**DynamoDB Table:** `aft-request`
```
┌────────────────────────────────────────────────┐
│ ID (Email)           │ Account Name           │
├──────────────────────┼────────────────────────┤
│ myproject+dev@...    │ DevAccount             │
│ Status: PENDING                               │
└────────────────────────────────────────────────┘
```

---

### After ~10 minutes:

**Service Catalog**
```
┌────────────────────────────────────────────────┐
│ Product Name         │ Status                 │
├──────────────────────┼────────────────────────┤
│ DevAccount           │ UNDER_CHANGE           │
│                                               │
│ Provisioning account via Control Tower...     │
└────────────────────────────────────────────────┘
```

---

### After ~20 minutes:

**AWS Organizations**
```
┌──────────────────────────────────────────────────────┐
│ Account Name │ Account ID   │ Email            │ Status│
├──────────────┼──────────────┼──────────────────┼──────┤
│ DevAccount   │ 123456789012 │ myproject+dev... │ACTIVE│
└──────────────────────────────────────────────────────┘
```

**✅ Account is ready to use!**

---

## 💡 Tips for Success

### ✅ DO:
- Use clear, descriptive account names
- Use unique emails (Gmail + trick works great!)
- Choose the correct OU (LearnMck for testing)
- Select appropriate environment tag
- Wait 20-25 minutes for provisioning

### ❌ DON'T:
- Reuse email addresses
- Use spaces in account names (use hyphens instead)
- Create multiple accounts simultaneously (wait for one to finish)
- Interrupt the workflow once started

---

## 🔍 How to Check Progress

### Quick Check:
```bash
# In AWS CLI
aws organizations list-accounts \
  --query "Accounts[?Email=='your-email@example.com']"
```

### Detailed Check:
1. **GitHub Actions** - See workflow completion
2. **CodePipeline** - See Terraform apply logs
3. **DynamoDB** - See request entry
4. **Service Catalog** - See provisioning status
5. **Organizations** - See final account

---

## 🎓 Learning Path

**Beginner:** Just use the workflow (5 minutes to learn)  
**Intermediate:** Understand the automation flow (this guide)  
**Advanced:** Customize workflow for your needs  
**Expert:** Extend AFT with custom code  

---

## 📞 Quick Reference

| What | Where | Time |
|------|-------|------|
| **Run Workflow** | [GitHub Actions](https://github.com/UnpredictablePrashant/MCK-aft/actions) | 30 seconds |
| **Check Pipeline** | [CodePipeline Console](https://ap-south-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/ct-aft-account-request/view) | ~3 minutes |
| **Check Account** | [AWS Organizations](https://console.aws.amazon.com/organizations/v2/home/accounts) | ~20 minutes |

---

**Last Updated:** December 8, 2025  
**Workflow Version:** 1.0  
**Complexity:** ⭐ Simple (No AWS/Terraform knowledge required!)

