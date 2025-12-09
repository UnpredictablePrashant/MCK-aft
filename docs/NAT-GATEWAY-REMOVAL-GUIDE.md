# 🎯 NAT Gateway Removal - Complete Guide

## Current Status

✅ **Investigated:** Multiple approaches to remove VPC from CodeBuild
❌ **Challenge:** AWS CLI doesn't support removing VPC configuration
✅ **Solution:** Manual console update (5 minutes) + Delete NAT Gateways

---

## 🚀 Quick Implementation (Choose Your Path)

### Option A: **Immediate Cost Savings** (Recommended)

Delete NAT Gateways NOW, fix CodeBuild VPC later:

```bash
# 1. Delete NAT Gateways (immediate $70/month savings)
aws ec2 delete-nat-gateway --nat-gateway-id nat-0b523f36f5a3b2a7d --region ap-south-1
aws ec2 delete-nat-gateway --nat-gateway-id nat-0a3b32c9efc6895e4 --region ap-south-1

# 2. Wait 5 minutes, then release Elastic IPs
sleep 300
aws ec2 describe-addresses \
  --filters "Name=domain,Values=vpc" "Name=network-interface-id,Values=" \
  --query 'Addresses[].AllocationId' \
  --output text \
  --region ap-south-1 | xargs -I {} aws ec2 release-address --allocation-id {} --region ap-south-1
```

**Impact:**
- ✅ **Immediate savings**: $70/month stops accruing
- ⚠️ **Next CodeBuild run will fail** (no internet access via VPC)
- ✅ **Forces you to fix VPC config** (documented below)

---

### Option B: **Proper Fix First, Then Delete**

Fix CodeBuild VPC via Console, then delete NAT:

---

## 📝 Step-by-Step: Remove VPC from CodeBuild (AWS Console)

### For Each Project (5 projects, ~1 minute each):

1. **Navigate to CodeBuild:**
   - Go to: https://ap-south-1.console.aws.amazon.com/codesuite/codebuild/projects
   - Select region: **ap-south-1**

2. **Projects to Update:**
   - `ct-aft-account-request`
   - `aft-global-customizations-terraform`
   - `ct-aft-account-provisioning-customizations`
   - `aft-account-customizations-terraform-v2`
   - `aft-create-pipeline-v2`

3. **For each project:**
   - Click project name
   - Click **"Edit"** dropdown → **"Environment"**
   - Scroll to **"Additional configuration"**
   - Find **"VPC"** section
   - Click **"Remove VPC"** or uncheck "Enable VPC configuration"
   - Click **"Update environment"**

4. **Verify:**
   - On project details page, "VPC" section should show "N/A" or be empty

---

## 🗑️ Delete NAT Gateways (After VPC Removal)

Once CodeBuild VPC is removed:

```bash
#Assume role in AFT Management Account
aws sts assume-role \
  --role-arn arn:aws:iam::809574937450:role/AWSControlTowerExecution \
  --role-session-name DeleteNAT \
  --profile ct-mgmt > /tmp/aft-delete-nat.json

export AWS_ACCESS_KEY_ID=$(cat /tmp/aft-delete-nat.json | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(cat /tmp/aft-delete-nat.json | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(cat /tmp/aft-delete-nat.json | jq -r '.Credentials.SessionToken')
export AWS_DEFAULT_REGION=ap-south-1

# Delete NAT Gateways
echo "Deleting NAT Gateway 1..."
aws ec2 delete-nat-gateway --nat-gateway-id nat-0b523f36f5a3b2a7d --region ap-south-1

echo "Deleting NAT Gateway 2..."
aws ec2 delete-nat-gateway --nat-gateway-id nat-0a3b32c9efc6895e4 --region ap-south-1

echo "Waiting 5 minutes for NAT Gateways to delete..."
sleep 300

# Release Elastic IPs
echo "Finding orphaned Elastic IPs..."
EIPS=$(aws ec2 describe-addresses \
  --filters "Name=domain,Values=vpc" \
  --query 'Addresses[?AssociationId==null].AllocationId' \
  --output text \
  --region ap-south-1)

if [ ! -z "$EIPS" ]; then
  echo "Releasing Elastic IPs: $EIPS"
  for EIP in $EIPS; do
    aws ec2 release-address --allocation-id $EIP --region ap-south-1
    echo "  Released: $EIP"
  done
  echo "✅ All Elastic IPs released"
else
  echo "⚠️ No orphaned Elastic IPs found (might need more time)"
fi

echo ""
echo "✅ NAT Gateway deletion complete!"
echo "💰 You're now saving ~$70/month!"
```

---

## 🧪 Testing After Changes

### Test Account Provisioning:

1. **Push a new account request** to GitHub (or use existing workflow)
2. **Monitor CodeBuild logs:**
   ```bash
   aws logs tail /aws/codebuild/ct-aft-account-request \
     --follow \
     --region ap-south-1
   ```
3. **Verify internet access:**
   - Should see successful GitHub clones
   - Terraform provider downloads should work
   - pip installs should succeed

### Expected Behavior:
- ✅ CodeBuild runs successfully without VPC
- ✅ Internet access via AWS's managed network (free)
- ✅ AWS service calls via AWS backbone network
- ✅ No NAT Gateway costs

---

## 📊 Cost Verification

After 24 hours, verify savings:

```bash
# Check Cost Explorer (may take 24-48 hours to reflect)
aws ce get-cost-and-usage \
  --time-period Start=2025-12-01,End=2025-12-31 \
  --granularity DAILY \
  --metrics UnblendedCost \
  --filter file://<(cat <<FILTER
{
  "Dimensions": {
    "Key": "SERVICE",
    "Values": ["Amazon Elastic Compute Cloud - Compute"]
  }
}
FILTER
) \
  --region us-east-1
```

**Expected Savings:**
- NAT Gateway: -$64.80/month
- Data processing: -$4.50/month
- **Total: ~$70/month = $840/year**

---

## 🔄 Rollback Plan

If issues occur, recreate NAT Gateway:

```bash
# Get subnet ID
SUBNET_ID="subnet-0be4f7f848072bad2"  # ap-south-1a

# Allocate new Elastic IP
ALLOC_ID=$(aws ec2 allocate-address \
  --domain vpc \
  --region ap-south-1 \
  --query 'AllocationId' \
  --output text)

# Create NAT Gateway
NAT_ID=$(aws ec2 create-nat-gateway \
  --subnet-id $SUBNET_ID \
  --allocation-id $ALLOC_ID \
  --region ap-south-1 \
  --query 'NatGateway.NatGatewayId' \
  --output text)

echo "NAT Gateway created: $NAT_ID"
echo "Wait 2-3 minutes for it to become available"

# Update route tables (if needed)
```

---

## ✅ Final Checklist

- [ ] CodeBuild VPC removed for all 5 projects (via Console)
- [ ] NAT Gateways deleted
- [ ] Elastic IPs released
- [ ] Test account provisioning (1 test account)
- [ ] Verify in Cost Explorer after 24 hours
- [ ] Update architecture documentation
- [ ] Celebrate $840/year savings! 🎉

---

## 📞 Support

If you encounter issues:
1. Check CodeBuild logs for errors
2. Verify internet access is working
3. Check this guide's rollback section
4. Contact AWS Support if needed

---

**Last Updated:** December 8, 2025
**Estimated Time:** 10-15 minutes
**Savings:** $840/year
**Risk Level:** Low (easy rollback)
