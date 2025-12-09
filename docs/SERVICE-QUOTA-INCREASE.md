# 📈 AWS Organizations Account Limit Increase Guide

## Current Situation
- **Current Limit:** 10 accounts
- **Accounts Used:** 10 (7 active + 3 suspended)
- **Target Limit:** 50-100 accounts
- **Quota Code:** L-29A0C5DF

---

## 🚀 Method 1: AWS Console (Recommended - Most Reliable)

### Step-by-Step Instructions:

1. **Navigate to Service Quotas Console**
   
   **Direct Link:** https://console.aws.amazon.com/servicequotas/home/services/organizations/quotas/L-29A0C5DF
   
   Or manually:
   - Go to AWS Console → Service Quotas
   - Select "AWS Services"
   - Search for "AWS Organizations"
   - Click "AWS Organizations"
   - Find "Default maximum number of accounts"

2. **Request Quota Increase**
   
   Click: **"Request increase at account level"**

3. **Fill in the Request Form**
   
   **Field: New quota value**
   - Suggested: **50** (for testing/development)
   - Or: **100** (for production use)
   
   **Field: Use case description**
   ```
   We are implementing AWS Account Factory for Terraform (AFT) to automate 
   multi-account AWS environment provisioning. We need to increase the account 
   limit from 10 to 50 to support:
   
   - Development, staging, and production environments
   - Multi-tenant application architecture
   - Isolated workload accounts for security and compliance
   - Testing and sandbox accounts for development teams
   
   Current usage: 7 active accounts + 3 test accounts
   Expected growth: 20-30 accounts in the next 6 months
   ```

4. **Submit Request**
   
   - Review your request
   - Click **"Request"**
   - You'll receive a confirmation email

5. **Wait for Approval**
   
   - **Typical approval time:** 1-2 business days
   - **Sometimes:** Instant approval (auto-approved)
   - Check email for status updates
   - Track in Service Quotas console

---

## 🖥️ Method 2: AWS CLI (Alternative)

```bash
# Assume role in Control Tower Management account
aws sts assume-role \
  --role-arn arn:aws:iam::535355705679:role/AWSControlTowerExecution \
  --role-session-name RequestQuota \
  --profile ct-mgmt > /tmp/quota-request.json

export AWS_ACCESS_KEY_ID=$(cat /tmp/quota-request.json | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(cat /tmp/quota-request.json | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(cat /tmp/quota-request.json | jq -r '.Credentials.SessionToken')

# Check current quota
aws service-quotas get-service-quota \
  --service-code organizations \
  --quota-code L-29A0C5DF \
  --region us-east-1

# Request increase to 50 accounts
aws service-quotas request-service-quota-increase \
  --service-code organizations \
  --quota-code L-29A0C5DF \
  --desired-value 50 \
  --region us-east-1

# Check request status
aws service-quotas list-requested-service-quota-change-history-by-quota \
  --service-code organizations \
  --quota-code L-29A0C5DF \
  --region us-east-1
```

---

## 📧 Method 3: AWS Support Case (If Auto-Approval Fails)

If the Service Quotas request is denied or delayed:

1. **Open AWS Support Case**
   - Go to: AWS Support Center
   - Click: "Create case"
   - Select: "Service limit increase"

2. **Case Details**
   - **Limit type:** Organizations
   - **Region:** Global (N/A)
   - **Limit:** Default maximum number of accounts
   - **New limit value:** 50 or 100
   - **Use case description:** (same as above)

3. **Response Time**
   - Basic/Developer Support: 12-24 hours
   - Business Support: 1-12 hours
   - Enterprise Support: 1-4 hours

---

## 💡 Recommended Values by Use Case

| Use Case | Recommended Limit | Justification |
|----------|------------------|---------------|
| **Testing/Development** | 20-30 | Small team, occasional testing |
| **Small Production** | 50 | Multiple environments per project |
| **Medium Production** | 100 | Multiple teams, multi-tenant |
| **Large Production** | 200-500 | Enterprise multi-account strategy |
| **Enterprise** | 1000+ | Large organizations (requires business case) |

---

## 🔍 Checking Your Request Status

### Via Console:
1. Go to Service Quotas → Dashboard
2. Click "Quota request history"
3. Filter by "AWS Organizations"
4. Check status: Pending / Approved / Denied

### Via CLI:
```bash
aws service-quotas list-requested-service-quota-change-history \
  --service-code organizations \
  --region us-east-1 \
  --query 'RequestedQuotas[?QuotaCode==`L-29A0C5DF`]' \
  --output table
```

---

## ⏰ What to Do While Waiting

While waiting for approval (1-2 business days):

### Immediate Action: Clean Up Suspended Accounts

```bash
# Remove 3 suspended accounts to free up slots NOW
aws organizations remove-account-from-organization --account-id 424668183885
aws organizations remove-account-from-organization --account-id 858039354119
aws organizations remove-account-from-organization --account-id 330857832892
```

This gives you **3 free slots immediately** to continue testing!

### Audit Existing Accounts
- Identify test accounts that can be removed
- Document account purposes
- Plan account naming convention

### Update AFT Configuration
- Review account request queue in DynamoDB
- Prioritize which accounts to create first
- Consider batch account creation after approval

---

## 📊 Expected Timeline

| Action | Time |
|--------|------|
| Submit quota increase request | 5 minutes |
| AWS initial review | 1-4 hours |
| Auto-approval (if eligible) | Instant - 24 hours |
| Manual review (if needed) | 1-2 business days |
| Total expected time | **1-2 business days** |

---

## ✅ Post-Approval Steps

Once approved:

1. **Verify New Limit**
   ```bash
   aws service-quotas get-service-quota \
     --service-code organizations \
     --quota-code L-29A0C5DF \
     --region us-east-1
   ```

2. **Resume AFT Account Creation**
   - Push new account requests to GitHub
   - Use GitHub Actions workflows
   - Monitor account provisioning

3. **Implement Account Lifecycle Policy**
   - Tag accounts appropriately
   - Set up automated cleanup for test accounts
   - Monitor account usage

---

## 🚨 Common Issues & Solutions

### Issue: Request Denied
**Solution:** Open AWS Support case with detailed business justification

### Issue: Slow Approval (>3 days)
**Solution:** Follow up via AWS Support case

### Issue: Can't Submit Request
**Solution:** Check IAM permissions for `servicequotas:RequestServiceQuotaIncrease`

### Issue: Need More Than 100 Accounts
**Solution:** Must provide detailed business case via AWS Support

---

## 📝 Tracking Document

| Date | Action | Status | New Limit |
|------|--------|--------|-----------|
| 2025-12-08 | Current state | ✅ | 10 |
| 2025-12-08 | Request submitted | ⏳ | 50 |
| TBD | Approval received | ⏳ | 50 |

---

## 🔗 Useful Links

- **Service Quotas Console:** https://console.aws.amazon.com/servicequotas/
- **Organizations Quota:** https://console.aws.amazon.com/servicequotas/home/services/organizations/quotas/L-29A0C5DF
- **AWS Support:** https://console.aws.amazon.com/support/home
- **Organizations Limits Docs:** https://docs.aws.amazon.com/organizations/latest/userguide/orgs_reference_limits.html

---

## 💰 Cost Impact

**Quota Increase Cost:** FREE ✅

- No charge for requesting limit increase
- No charge for having higher quota
- Only pay for resources you actually use
- Each account still incurs standard AWS charges

---

**Next Steps:**
1. ✅ Submit quota increase request via Console (5 minutes)
2. ⏳ Wait for approval (1-2 business days)
3. 🔄 Meanwhile: Remove suspended accounts to free 3 slots
4. 🚀 Resume account creation after approval

