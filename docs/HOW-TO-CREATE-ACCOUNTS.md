# 🚀 How to Create AWS Accounts with AFT

This guide explains how to create new AWS accounts using the GitHub Actions workflow.

## ⚡ Quick Start (3 Steps!)

### 1. Go to GitHub Actions

Navigate to: **[GitHub Actions](https://github.com/UnpredictablePrashant/MCK-aft/actions)**

### 2. Run the Workflow

1. Click on **"🚀 Create New AWS Account"** in the left sidebar
2. Click the **"Run workflow"** button
3. Fill in the form:
   - **Account Name**: e.g., `DevAccount`, `ProdAccount`
   - **Account Email**: Must be unique (e.g., `myproject+dev@gmail.com`)
   - **Organizational Unit**: Choose `LearnMck` or `AFTLearn`
   - **Environment**: Choose `Development`, `Testing`, `Staging`, or `Production`
4. Click **"Run workflow"**

### 3. Wait for Account Creation

The account will be created automatically in ~20 minutes!

---

## 📊 What Happens After You Click "Run"?

```
GitHub Actions Workflow
    ↓
Pushes to account-request repository
    ↓
EventBridge detects change (2 minutes)
    ↓
CodePipeline runs Terraform (3 minutes)
    ↓
DynamoDB entry created
    ↓
Lambda processes request (2 minutes)
    ↓
SQS → Account Processor (5 minutes)
    ↓
Service Catalog provisions account (10 minutes)
    ↓
Account appears in AWS Organizations! ✅
```

**Total Time:** ~20 minutes

---

## 📋 Form Fields Explained

### Account Name
- **What:** Display name for your account
- **Example:** `DevAccount`, `MyProjectProd`, `TestEnvironment`
- **Rules:** Can contain letters, numbers, spaces

### Account Email
- **What:** Unique email for this AWS account
- **Example:** `myproject+dev@gmail.com`
- **Rules:** 
  - Must be unique across ALL AWS accounts
  - Can use `+` trick with Gmail (e.g., `email+dev@gmail.com`)
  - Cannot be reused

### Organizational Unit (OU)
- **What:** Where in your AWS Organization this account goes
- **Options:**
  - `LearnMck` - Main learning OU (recommended for testing)
  - `AFTLearn` - Alternative OU
- **Tip:** Use `LearnMck` for most accounts

### Environment
- **What:** Tags your account for easy identification
- **Options:**
  - `Development` - For dev/experimental work
  - `Testing` - For QA/testing
  - `Staging` - Pre-production
  - `Production` - Live production accounts

---

## 🔍 How to Monitor Progress

### Option 1: GitHub Actions Tab
- Go to your workflow run
- Check the "Summary" for detailed timeline
- See real-time logs

### Option 2: AWS Console

**CodePipeline** (See Terraform apply):
```
https://ap-south-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/ct-aft-account-request/view
```

**AWS Organizations** (See created account):
```
https://console.aws.amazon.com/organizations/v2/home/accounts
```

**Step Functions** (See provisioning):
```
https://ap-south-1.console.aws.amazon.com/states/home?region=ap-south-1
```

---

## ✅ How to Know When It's Done?

You'll know the account is ready when:

1. **AWS Organizations** shows the account as `ACTIVE`
2. **Service Catalog** shows status as `AVAILABLE`
3. **Email** (account email) receives AWS notifications

---

## 🎯 Example: Creating a Dev Account

Let's create a development account step-by-step:

1. **Go to:** [GitHub Actions](https://github.com/UnpredictablePrashant/MCK-aft/actions)

2. **Click:** "🚀 Create New AWS Account"

3. **Fill the form:**
   ```
   Account Name:    MyProjectDev
   Account Email:   ravish.snkhyn+myproject-dev@gmail.com
   OU:             LearnMck
   Environment:    Development
   ```

4. **Click:** "Run workflow"

5. **Wait:** ~20 minutes

6. **Check:** AWS Organizations for your new account!

---

## 💡 Pro Tips

### Use Gmail's + Trick
If you have `myemail@gmail.com`, you can create unlimited unique emails:
- `myemail+dev@gmail.com`
- `myemail+test@gmail.com`
- `myemail+prod@gmail.com`

All emails go to the same inbox!

### Naming Convention
Use clear, consistent names:
- ✅ Good: `ProjectName-Dev`, `AppName-Prod`
- ❌ Bad: `test123`, `myaccount`

### Check Before Creating
Make sure the email hasn't been used before:
```bash
aws organizations list-accounts --query "Accounts[?Email=='your-email@example.com']"
```

---

## ❓ Troubleshooting

### Workflow Fails at "Commit" Step
**Problem:** Git configuration issue  
**Solution:** This is rare, try re-running the workflow

### Account Not Appearing After 30 Minutes
**Problem:** Possible AFT processing error  
**Solution:** 
1. Check CodePipeline for errors
2. Check Lambda logs: `/aws/lambda/aft-account-request-processor`

### Email Already Used Error
**Problem:** Email was used for another account  
**Solution:** Use a different email address

---

## 📚 Additional Resources

- [AWS Organizations](https://docs.aws.amazon.com/organizations/)
- [AFT Documentation](https://docs.aws.amazon.com/controltower/latest/userguide/aft-overview.html)
- [Main README](../README.md)
- [AFT Automation Summary](./AFT-AUTOMATION-SUMMARY.md)

---

## 🆘 Need Help?

1. Check the [Troubleshooting](#-troubleshooting) section above
2. Review CodePipeline logs in AWS Console
3. Check DynamoDB table `aft-request` for your entry

---

**Last Updated:** December 8, 2025  
**Workflow Version:** 1.0  
**AFT Version:** 1.17.0

