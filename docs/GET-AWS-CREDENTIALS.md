# 🔑 How to Get Fresh AWS Credentials

There are two methods to get temporary AWS credentials. Choose the one that applies to you:

---

## Method 1: AWS SSO (IAM Identity Center) - RECOMMENDED

If you log in to AWS using a URL like `https://d-xxxxxxxxxx.awsapps.com/start` or use AWS SSO:

### Step 1: Log in to AWS SSO
1. Go to your AWS SSO portal (you should have this URL bookmarked)
   - Usually looks like: `https://d-xxxxxxxxxx.awsapps.com/start`
   - Or: `https://[your-org].awsapps.com/start`

2. Sign in with your credentials

### Step 2: Access the Management Account
1. Find **"HV_academics"** or **"CT Management"** account in the list
2. Click on it

### Step 3: Get Command Line Credentials
1. Click **"Command line or programmatic access"**
2. You'll see three options - choose **Option 2** or **Option 3**:

#### Option 2: Add a profile to your AWS credentials file (macOS/Linux)
```bash
[ct-mgmt]
aws_access_key_id = ASIA...
aws_secret_access_key = abc123...
aws_session_token = IQoJb3JpZ2luX2VjE...
```

**Copy these three lines** and follow these steps:

```bash
# Open credentials file
nano ~/.aws/credentials

# Find the [ct-mgmt] section
# Replace the old credentials with the new ones you just copied
# Should look like:

[ct-mgmt]
aws_access_key_id = ASIA[NEW_KEY_HERE]
aws_secret_access_key = [NEW_SECRET_HERE]
aws_session_token = IQoJb3JpZ2lu[VERY_LONG_TOKEN_HERE]

# Save and exit
# Press: Ctrl+O → Enter → Ctrl+X
```

### Step 4: Verify
```bash
aws sts get-caller-identity --profile ct-mgmt
```

You should see your account ID: `535355705679`

---

## Method 2: IAM User with Console Access

If you log in with a username/password directly to AWS Console:

### Step 1: Log in to AWS Console
1. Go to: `https://console.aws.amazon.com/`
2. Sign in with your IAM user credentials
3. Make sure you're in the **HV_academics** account (535355705679)

### Step 2: Navigate to IAM
1. In the search bar, type **"IAM"**
2. Click on **IAM** service

### Step 3: Create/Rotate Access Keys
1. In the left sidebar, click **"Users"**
2. Click on your username (e.g., "Ravish")
3. Click the **"Security credentials"** tab
4. Scroll to **"Access keys"** section

#### If you have 2 access keys already:
   - Delete the oldest one (click **Delete**)
   - Wait 10 seconds

#### Create new access key:
   - Click **"Create access key"**
   - Choose **"Command Line Interface (CLI)"**
   - Check the confirmation box
   - Click **"Next"**
   - Add description: "E2E Test - Dec 2025"
   - Click **"Create access key"**

### Step 4: Copy Credentials
You'll see:
```
Access key ID: AKIA[SOMETHING]
Secret access key: [LONG_STRING]
```

**IMPORTANT:** Click **"Download .csv file"** (you can only see the secret once!)

### Step 5: Update Credentials File
```bash
# Open credentials file
nano ~/.aws/credentials

# Update or add [ct-mgmt] section:
[ct-mgmt]
aws_access_key_id = AKIA[YOUR_NEW_KEY]
aws_secret_access_key = [YOUR_NEW_SECRET]
# NOTE: IAM user credentials don't have session_token, so remove that line if present

# Save and exit
# Press: Ctrl+O → Enter → Ctrl+X
```

### Step 6: Verify
```bash
aws sts get-caller-identity --profile ct-mgmt
```

---

## Method 3: Using AWS CLI SSO Login (If Configured)

If you have AWS SSO configured in your CLI:

```bash
# Configure SSO (one-time setup)
aws configure sso

# Follow prompts:
# SSO start URL: https://[your-org].awsapps.com/start
# SSO region: us-east-1
# Account: 535355705679 (HV_academics)
# Role: AdministratorAccess or AWSControlTowerExecution
# Profile name: ct-mgmt

# Then login:
aws sso login --profile ct-mgmt

# This will open a browser for authentication
```

---

## Troubleshooting

### Error: "ExpiredToken"
- Your credentials have expired (SSO tokens last 1-12 hours)
- Get fresh credentials using Method 1 or 3

### Error: "InvalidAccessKeyId"
- Wrong access key
- Re-copy credentials carefully
- Make sure there are no extra spaces

### Error: "Access Denied"
- You might be in the wrong account
- Verify account ID: `aws sts get-caller-identity --profile ct-mgmt`
- Should show: `"Account": "535355705679"`

### Can't find credentials in console
- You might be using SSO (use Method 1)
- Check with your AWS admin

---

## Quick Reference

### Credentials File Location:
```bash
~/.aws/credentials
```

### Expected Format:
```ini
[ct-mgmt]
aws_access_key_id = ASIA... or AKIA...
aws_secret_access_key = abc123...
aws_session_token = IQoJb3... (only for SSO/temporary credentials)
```

### Test Credentials:
```bash
aws sts get-caller-identity --profile ct-mgmt
```

### Expected Output:
```json
{
    "UserId": "AIDAXXXXX:ravish",
    "Account": "535355705679",
    "Arn": "arn:aws:sts::535355705679:assumed-role/..."
}
```

---

## After Getting Credentials

Once your credentials are updated, run the E2E test:

```bash
bash /Users/ravish_sankhyan-guva/Devops-Sre-Aft/MCK-aft/scripts/run-e2e-test-after-account-close.sh
```

---

## Visual Guide

```
SSO Login Flow:
===============
1. Browser → AWS SSO Portal
2. Click "HV_academics" account
3. Click "Command line or programmatic access"
4. Copy credentials (3 lines)
5. Paste into ~/.aws/credentials
6. Done! ✅

IAM User Flow:
=============
1. Browser → AWS Console
2. IAM → Users → Your username
3. Security credentials → Create access key
4. Download .csv file
5. Copy access key ID and secret
6. Paste into ~/.aws/credentials
7. Done! ✅
```

---

**Most users use SSO (Method 1)** - this is the recommended approach!

