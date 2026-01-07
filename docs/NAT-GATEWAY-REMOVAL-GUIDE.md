# 🚫 NAT Gateway Removal Guide

This guide explains how to remove NAT Gateways from AFT to save approximately $840/year in costs.

---

## 🎯 Overview

### Why Remove NAT Gateways?

| Component | Monthly Cost | Annual Cost |
|-----------|-------------|-------------|
| NAT Gateway (2x) | $64.80 | $777.60 |
| Data Processing | ~$4.50 | ~$54.00 |
| **Total** | **~$69.30** | **~$831.60** |

**Savings: ~$831/year by removing NAT Gateways!**

### Why It Works

AFT uses CodeBuild for Terraform operations. CodeBuild can run either:

1. **With VPC** (default) - Requires NAT Gateway for internet access
2. **Without VPC** - Uses AWS-managed network with free internet access

For AFT, running without VPC is perfectly fine because:
- ✅ All AWS service access works (via AWS backbone)
- ✅ Internet access works (GitHub, Terraform registry)
- ✅ Security is maintained (IAM-based, not network-based)

---

## 📐 Architecture Comparison

### Before (With NAT Gateway)

```
┌─────────────────────────────────────────┐
│           AFT VPC                        │
│  ┌─────────────────────────────────────┐│
│  │        Private Subnet               ││
│  │  ┌────────────────┐                 ││
│  │  │   CodeBuild    │                 ││
│  │  │  (VPC-attached)│                 ││
│  │  └───────┬────────┘                 ││
│  │          │                          ││
│  │          ↓                          ││
│  │  ┌────────────────┐                 ││
│  │  │  NAT Gateway   │ ← $32.40/month  ││
│  │  └───────┬────────┘                 ││
│  └──────────┼──────────────────────────┘│
│             ↓                            │
│  ┌──────────────────┐                   │
│  │ Internet Gateway │                   │
│  └──────────────────┘                   │
│             ↓                            │
│        Internet                          │
└─────────────────────────────────────────┘
```

### After (No NAT Gateway)

```
┌─────────────────────────────────────────┐
│       AWS-Managed Network                │
│  ┌────────────────────────────────────┐ │
│  │         CodeBuild                   │ │
│  │       (No VPC config)               │ │
│  │                                     │ │
│  │  ┌─────────────────────────────┐   │ │
│  │  │ AWS Services (Free):        │   │ │
│  │  │  → DynamoDB                 │   │ │
│  │  │  → S3                       │   │ │
│  │  │  → SSM                      │   │ │
│  │  │  → Lambda                   │   │ │
│  │  └─────────────────────────────┘   │ │
│  │                                     │ │
│  │  ┌─────────────────────────────┐   │ │
│  │  │ Internet (Free):            │   │ │
│  │  │  → GitHub                   │   │ │
│  │  │  → Terraform Registry       │   │ │
│  │  │  → PyPI                     │   │ │
│  │  └─────────────────────────────┘   │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘

Cost: $0/month! 🎉
```

---

## 🔧 Implementation Steps

### Step 1: Verify Current Configuration

```bash
cd /Users/ravish_sankhyan-guva/Devops-Sre-Aft/MCK-aft/learn-terraform-aws-control-tower-aft

# Check current setting
grep -A5 "aft_enable_vpc" main.tf
```

### Step 2: Update Terraform Configuration

Edit `main.tf`:

```hcl
module "aft" {
  source = "./local-aft-module"
  
  # ... other configuration ...

  # 💰 DISABLE VPC to eliminate NAT Gateway costs (~$840/year savings)
  aft_enable_vpc = false

  # ... rest of configuration ...
}
```

### Step 3: Plan Changes

```bash
terraform plan -out=no-nat.tfplan
```

**Expected output:**
```
# aws_codebuild_project.aft_account_request will be updated
  ~ vpc_config = [] # Will be removed

Plan: 0 to add, 5 to change, 0 to destroy.
```

### Step 4: Apply Changes

```bash
terraform apply no-nat.tfplan
```

This updates CodeBuild projects to remove VPC configuration.

### Step 5: Test Account Provisioning

```bash
# Trigger a test by pushing to account-request repo
# Or run the workflow manually

# Monitor the pipeline
aws codepipeline get-pipeline-state \
  --name ct-aft-account-request \
  --region ap-south-1
```

### Step 6: Clean Up NAT Gateways (After Testing)

Once confirmed working:

```bash
# Delete NAT Gateways
aws ec2 describe-nat-gateways \
  --filter "Name=state,Values=available" \
  --query 'NatGateways[*].[NatGatewayId,VpcId]' \
  --region ap-south-1 \
  --output table

# Delete each NAT Gateway
aws ec2 delete-nat-gateway \
  --nat-gateway-id nat-xxxxxxxxx \
  --region ap-south-1

# Wait 5 minutes, then release Elastic IPs
sleep 300

# Find unassociated EIPs
aws ec2 describe-addresses \
  --filters "Name=domain,Values=vpc" \
  --query 'Addresses[?AssociationId==`null`].[AllocationId,PublicIp]' \
  --region ap-south-1 \
  --output table

# Release each EIP
aws ec2 release-address --allocation-id eipalloc-xxxxxxxxx --region ap-south-1
```

---

## ✅ Verification Checklist

After implementation, verify:

- [ ] CodePipeline triggers on GitHub push
- [ ] CodeBuild successfully clones from GitHub
- [ ] Terraform downloads work
- [ ] Python pip packages install
- [ ] DynamoDB writes succeed
- [ ] Service Catalog provisioning works
- [ ] Account creation completes end-to-end
- [ ] CloudWatch logs are captured
- [ ] No errors in Lambda functions
- [ ] Step Functions execute successfully

### Quick Test Script

```bash
# Check CodeBuild project has no VPC config
aws codebuild batch-get-projects \
  --names ct-aft-account-request \
  --query 'projects[0].vpcConfig' \
  --region ap-south-1

# Should return: null or {}
```

---

## 🔄 Rollback Plan

If issues occur, revert is easy:

### Step 1: Update Configuration

```hcl
# In main.tf, change:
aft_enable_vpc = true   # Revert to true
```

### Step 2: Apply

```bash
terraform apply
```

This recreates NAT Gateways and VPC configuration.

**Rollback Time:** 10-15 minutes  
**Risk:** Low (easy to revert)

---

## 🔐 Security Comparison

| Security Control | With VPC + NAT | Without VPC |
|------------------|----------------|-------------|
| Outbound Internet | Via NAT Gateway | Direct (AWS-managed) |
| Inbound Internet | Blocked by SG | Blocked (no listener) |
| AWS Service Access | Via Private or NAT | Via AWS Backbone |
| Authentication | IAM Roles | IAM Roles |
| Encryption | TLS | TLS |
| Logging | CloudWatch | CloudWatch |
| **Cost** | **$70/month** | **$0** |

### Why It's Still Secure

1. **IAM Role-Based Access:** CodeBuild uses IAM roles, not network security
2. **Encrypted Connections:** All traffic uses HTTPS/TLS
3. **No Inbound Access:** CodeBuild cannot receive inbound connections
4. **AWS-Managed Infrastructure:** Runs in AWS's secure, isolated network
5. **CloudWatch Logging:** All actions logged and auditable

---

## ⚠️ When NOT to Remove NAT Gateway

Keep NAT Gateway if you need:

1. **Private data sources** - Access to on-premises databases via VPN
2. **Custom network filtering** - Network-level egress filtering required
3. **Compliance requirements** - Regulatory mandates for private subnets
4. **VPC peering** - Access to resources in peered VPCs

### For Standard AFT (Remove NAT Gateway)

- ✅ Standard AFT deployment
- ✅ Public GitHub repositories
- ✅ Public Terraform registries
- ✅ AWS service access only
- ✅ No hybrid cloud connectivity needed

---

## 📊 Cost Analysis Summary

### Before

| Resource | Quantity | Monthly | Annual |
|----------|----------|---------|--------|
| NAT Gateway | 2 | $64.80 | $777.60 |
| Data Processing | 100 GB | $4.50 | $54.00 |
| **Total** | | **$69.30** | **$831.60** |

### After

| Resource | Quantity | Monthly | Annual |
|----------|----------|---------|--------|
| **Total** | | **$0.00** | **$0.00** |

### Annual Savings: **$831.60** 💰

---

## 🎯 Benefits Summary

### Cost Benefits
- ✅ **$831/year saved** (NAT Gateway + data transfer)
- ✅ **$0 ongoing network costs**
- ✅ No Elastic IP costs
- ✅ No cross-AZ data transfer costs

### Operational Benefits
- ✅ **Simpler architecture** (fewer moving parts)
- ✅ **Faster builds** (no VPC attachment overhead)
- ✅ **No NAT Gateway health monitoring** needed
- ✅ **No VPC maintenance**
- ✅ **Easier troubleshooting** (no network layer complexity)

### Performance Benefits
- ✅ **Same latency** for AWS services (AWS backbone)
- ✅ **Potentially faster** GitHub/internet access
- ✅ **No ENI attachment delay** for CodeBuild

---

## 📚 Additional Resources

- [AFT Architecture (No NAT)](./AFT-ARCHITECTURE-NO-NAT.md) - Detailed architecture
- [AWS CodeBuild VPC Support](https://docs.aws.amazon.com/codebuild/latest/userguide/vpc-support.html)
- [AWS NAT Gateway Pricing](https://aws.amazon.com/vpc/pricing/)
- [AFT Documentation](https://docs.aws.amazon.com/controltower/latest/userguide/aft-overview.html)

---

**Last Updated:** January 2026  
**Implementation Complexity:** Low (10-15 minutes)  
**Risk:** Low (easy rollback)  
**Recommendation:** ⭐⭐⭐⭐⭐ **Highly Recommended**

