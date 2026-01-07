# 🔑 Get AWS Credentials Guide

This guide explains how to obtain AWS credentials for accounts created by AFT.

---

## 🎯 Overview

There are multiple ways to access AWS accounts created through AFT:

| Method | Best For | Security |
|--------|----------|----------|
| **AWS SSO** | Daily use, console access | ✅ Most secure |
| **CLI with SSO** | Development, scripting | ✅ Secure |
| **IAM User** | Legacy applications | ⚠️ Requires rotation |
| **Assume Role** | Cross-account access | ✅ Secure |

---

## 🔐 Method 1: AWS SSO (Recommended)

### Step 1: Access SSO Portal

Go to your organization's SSO portal:
```
https://d-xxxxxxxxxx.awsapps.com/start
```

Or find it in AWS Organizations:
```
https://console.aws.amazon.com/singlesignon/home
```

### Step 2: Sign In

1. Enter your SSO username
2. Enter your password
3. Complete MFA (if enabled)

### Step 3: Select Account

After login, you'll see a list of accounts you have access to:

```
┌─────────────────────────────────────────┐
│  Available Accounts                      │
├─────────────────────────────────────────┤
│  📁 MyDevAccount (123456789012)         │
│     → Management console                 │
│     → Command line or programmatic       │
│                                          │
│  📁 MyTestAccount (234567890123)        │
│     → Management console                 │
│     → Command line or programmatic       │
└─────────────────────────────────────────┘
```

### Step 4: Get CLI Credentials

1. Click on the account
2. Click **"Command line or programmatic access"**
3. Choose your option:

**Option 1: Environment Variables (Temporary)**
```bash
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
```

**Option 2: Add to `~/.aws/credentials`**
```ini
[my-dev-account]
aws_access_key_id = ASIA...
aws_secret_access_key = ...
aws_session_token = ...
```

---

## 💻 Method 2: AWS CLI with SSO

### Step 1: Configure SSO Profile

```bash
aws configure sso
```

Follow the prompts:
```
SSO session name (Recommended): my-org-sso
SSO start URL [None]: https://d-xxxxxxxxxx.awsapps.com/start
SSO region [None]: ap-south-1
SSO registration scopes [sso:account:access]:
```

### Step 2: Login via Browser

```bash
aws sso login --profile my-dev-account
```

A browser window opens. Authorize the request.

### Step 3: Use the Profile

```bash
# List S3 buckets using SSO profile
aws s3 ls --profile my-dev-account

# Set as default profile
export AWS_PROFILE=my-dev-account
aws s3 ls
```

### Example SSO Config

`~/.aws/config`:
```ini
[profile my-dev-account]
sso_session = my-org-sso
sso_account_id = 123456789012
sso_role_name = AWSAdministratorAccess
region = ap-south-1
output = json

[sso-session my-org-sso]
sso_start_url = https://d-xxxxxxxxxx.awsapps.com/start
sso_region = ap-south-1
sso_registration_scopes = sso:account:access
```

---

## 👤 Method 3: IAM User Credentials

### For AFT-Created Student Users

AFT can automatically create IAM users with credentials. Check your account for:

```bash
# List IAM users in the account
aws iam list-users --profile your-account
```

### Get Access Keys

**Via Console:**
1. Go to IAM Console
2. Click on Users
3. Select your user
4. Go to "Security credentials" tab
5. Create access key

**Via CLI:**
```bash
aws iam create-access-key \
  --user-name student-user \
  --query 'AccessKey.[AccessKeyId,SecretAccessKey]' \
  --output text
```

### Store Credentials

Add to `~/.aws/credentials`:
```ini
[my-account]
aws_access_key_id = AKIA...
aws_secret_access_key = your-secret-key
region = ap-south-1
```

---

## 🔄 Method 4: Assume Role (Cross-Account)

### From Control Tower Management Account

```bash
# Assume role in AFT Management account
aws sts assume-role \
  --role-arn arn:aws:iam::809574937450:role/AWSControlTowerExecution \
  --role-session-name MySession \
  --profile ct-mgmt
```

### Extract and Use Credentials

```bash
# Get credentials
CREDS=$(aws sts assume-role \
  --role-arn arn:aws:iam::TARGET_ACCOUNT_ID:role/AWSControlTowerExecution \
  --role-session-name MySession \
  --profile ct-mgmt)

# Export them
export AWS_ACCESS_KEY_ID=$(echo $CREDS | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDS | jq -r '.Credentials.SessionToken')

# Now you have access to the target account
aws sts get-caller-identity
```

### Use Named Profile for Assume Role

Add to `~/.aws/config`:
```ini
[profile ct-mgmt]
region = ap-south-1
# Your management account credentials

[profile aft-management]
role_arn = arn:aws:iam::809574937450:role/AWSControlTowerExecution
source_profile = ct-mgmt
region = ap-south-1

[profile student-account-123]
role_arn = arn:aws:iam::123456789012:role/AWSControlTowerExecution
source_profile = ct-mgmt
region = ap-south-1
```

Then use:
```bash
aws s3 ls --profile aft-management
aws s3 ls --profile student-account-123
```

---

## 🔧 Setting Up AWS CLI

### Install AWS CLI v2

**macOS:**
```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

**Linux:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Windows:**
Download and run: https://awscli.amazonaws.com/AWSCLIV2.msi

### Verify Installation

```bash
aws --version
# aws-cli/2.x.x Python/3.x.x ...
```

### Configure Default Profile

```bash
aws configure
```

Enter:
```
AWS Access Key ID: AKIA...
AWS Secret Access Key: your-secret
Default region name: ap-south-1
Default output format: json
```

---

## 📋 Quick Reference

### Check Current Identity

```bash
aws sts get-caller-identity
```

Output:
```json
{
    "UserId": "AROAXXXXXXXXX:session-name",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:assumed-role/RoleName/session-name"
}
```

### List Available Profiles

```bash
aws configure list-profiles
```

### Switch Profiles

```bash
# Using --profile flag
aws s3 ls --profile my-account

# Or export
export AWS_PROFILE=my-account
aws s3 ls
```

### Refresh SSO Login

```bash
aws sso login --profile my-account
```

---

## 🔐 Security Best Practices

### DO ✅

- Use SSO whenever possible
- Enable MFA for all users
- Use temporary credentials (assume role)
- Rotate access keys regularly
- Use least-privilege permissions

### DON'T ❌

- Never commit credentials to Git
- Don't share access keys
- Don't use root account for daily work
- Don't create long-lived access keys

### Protect Your Credentials File

```bash
chmod 600 ~/.aws/credentials
chmod 600 ~/.aws/config
```

### Add to `.gitignore`

```
.aws/
credentials
*.pem
*.key
```

---

## 🔍 Troubleshooting

### "ExpiredToken" Error

```
An error occurred (ExpiredToken): The security token included in the request is expired
```

**Solution:** Refresh your session
```bash
# For SSO
aws sso login --profile my-account

# For assume role - run the assume-role command again
```

### "InvalidIdentityToken" Error

```
An error occurred (InvalidIdentityToken): Token is not valid
```

**Solution:** Check your clock synchronization
```bash
# macOS/Linux
sudo ntpdate time.apple.com
```

### "Access Denied" Error

```
An error occurred (AccessDenied): User is not authorized
```

**Solution:** 
1. Check you're using the right profile
2. Verify your role has required permissions
3. Check SCPs aren't blocking the action

### Profile Not Found

```
The config profile (my-profile) could not be found
```

**Solution:** Check your config file
```bash
cat ~/.aws/config
cat ~/.aws/credentials
```

---

## 📚 Account IDs Reference

| Account | ID | Role |
|---------|-----|------|
| Control Tower Management | 535355705679 | ct-mgmt profile |
| AFT Management | 809574937450 | AWSControlTowerExecution |
| Log Archive | 180574905686 | AWSControlTowerExecution |
| Audit | 002506421448 | AWSControlTowerExecution |

---

## 🔗 Related Links

- [AWS CLI Configuration Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- [AWS SSO User Guide](https://docs.aws.amazon.com/singlesignon/latest/userguide/)
- [IAM Roles for Cross-Account Access](https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html)

---

**Last Updated:** January 2026  
**Questions?** Check [Troubleshooting](./TROUBLESHOOTING.md)

