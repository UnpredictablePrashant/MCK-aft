# 🏗️ AFT Architecture Without NAT Gateway

## 🎯 Design Goal
Eliminate NAT Gateway costs (~$840/year) while maintaining full AFT functionality for account provisioning and customization.

---

## 📐 Architecture Overview

### High-Level Design
```
┌─────────────────────────────────────────────────────────────────────┐
│                       AFT Deployment Module                          │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                   AFT Management Account                       │ │
│  │                                                                │ │
│  │  ┌──────────────────┐         ┌──────────────────┐           │ │
│  │  │ Left Pipeline    │         │ Right Pipeline   │           │ │
│  │  │ (Account Request)│         │ (Customizations) │           │ │
│  │  │                  │         │                  │           │ │
│  │  │  ┌────────────┐  │         │  ┌────────────┐ │           │ │
│  │  │  │  GitHub    │  │         │  │  GitHub    │ │           │ │
│  │  │  │  VCS       │  │         │  │  VCS       │ │           │ │
│  │  │  └─────┬──────┘  │         │  └─────┬──────┘ │           │ │
│  │  │        │         │         │        │        │           │ │
│  │  │        ↓         │         │        ↓        │           │ │
│  │  │  ┌────────────┐  │         │  ┌────────────┐ │           │ │
│  │  │  │ CodeBuild  │◄─┼─────────┼─►│ CodeBuild  │ │           │ │
│  │  │  │ (No VPC!)  │  │         │  │ (No VPC!)  │ │           │ │
│  │  │  └─────┬──────┘  │         │  └─────┬──────┘ │           │ │
│  │  │        │         │         │        │        │           │ │
│  │  │        ↓         │         │        ↓        │           │ │
│  │  │  ┌────────────┐  │         │  ┌────────────┐ │           │ │
│  │  │  │ DynamoDB   │  │         │  │ Step       │ │           │ │
│  │  │  │ (aft-      │  │         │  │ Functions  │ │           │ │
│  │  │  │ request)   │  │         │  │            │ │           │ │
│  │  │  └────────────┘  │         │  └────────────┘ │           │ │
│  │  └──────────────────┘         └──────────────────┘           │ │
│  │                                                                │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                ↓                                     │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │            Control Tower Management Account                     │ │
│  │                                                                │ │
│  │  ┌──────────────────┐         ┌──────────────────┐           │ │
│  │  │  AWS Service     │         │  AWS Control     │           │ │
│  │  │  Catalog         │         │  Tower           │           │ │
│  │  └──────────────────┘         └──────────────────┘           │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                ↓                                     │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                      Vended Account                            │ │
│  │                   (Newly Created Account)                      │ │
│  └────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Key Architectural Changes

### 1. **CodeBuild Without VPC Configuration**

#### Current (With NAT Gateway):
```terraform
resource "aws_codebuild_project" "aft_account_request" {
  vpc_config {
    vpc_id             = "vpc-0d2b98864f8115e76"
    subnets            = ["subnet-0d255e7cd8ff23032"]
    security_group_ids = ["sg-xxxxx"]
  }
}
```

#### New (No VPC - No NAT Gateway Needed):
```terraform
resource "aws_codebuild_project" "aft_account_request" {
  # No vpc_config block!
  # CodeBuild runs in AWS-managed network with free internet access
}
```

**Impact:**
- ✅ CodeBuild gets **free internet access** via AWS's infrastructure
- ✅ No NAT Gateway required
- ✅ No Elastic IP required
- ✅ No cross-AZ data transfer charges
- ✅ **Saves ~$840/year**

---

## 🌐 Network Connectivity Flow

### Without NAT Gateway Architecture:

```
┌─────────────────────────────────────────────────────────────────┐
│                    AFT Management Account                       │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │         CodeBuild (AWS-Managed Network)                    │ │
│  │                                                            │ │
│  │  Internet Access:                                         │ │
│  │  ├─► GitHub.com (HTTPS) ──────────────┐                  │ │
│  │  ├─► releases.hashicorp.com ──────────┤                  │ │
│  │  ├─► pypi.org (pip packages) ─────────┤                  │ │
│  │  └─► registry.terraform.io ───────────┤                  │ │
│  │                                         │                  │ │
│  │                                         ↓                  │ │
│  │                              [AWS Internet Gateway]       │ │
│  │                              (Managed by AWS - Free)      │ │
│  │                                                            │ │
│  │  AWS Services (via AWS Private Network):                  │ │
│  │  ├─► DynamoDB (aft-request table)                        │ │
│  │  ├─► S3 (aft-backend buckets)                            │ │
│  │  ├─► SSM Parameter Store                                  │ │
│  │  ├─► CloudWatch Logs                                      │ │
│  │  ├─► STS (AssumeRole)                                     │ │
│  │  ├─► IAM                                                   │ │
│  │  └─► Service Catalog                                      │ │
│  │       (All via AWS backbone - No internet needed)        │ │
│  │                                                            │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ⚠️ NO VPC REQUIRED = NO NAT GATEWAY COSTS!                    │
└──────────────────────────────────────────────────────────────────┘
```

---

## 🔐 Security Considerations

### CodeBuild Without VPC:

**✅ Still Secure:**
1. **IAM Role-Based Access:** CodeBuild uses IAM roles, not network security
2. **Encrypted Connections:** All traffic (GitHub, AWS APIs) uses HTTPS/TLS
3. **No Inbound Access:** CodeBuild cannot receive inbound connections
4. **AWS-Managed Infrastructure:** Runs in AWS's secure, isolated network
5. **CloudWatch Logging:** All actions logged and auditable

**What Changes:**
- ❌ No Security Groups (not needed - no VPC)
- ❌ No Network ACLs (not needed - no VPC)
- ✅ IAM policies control all access
- ✅ Resource-based policies control AWS service access

**Comparison:**

| Security Control | With VPC + NAT | Without VPC |
|------------------|----------------|-------------|
| Outbound Internet | Via NAT Gateway | Direct (AWS-managed) |
| Inbound Internet | Blocked by Security Group | Blocked (no listener) |
| AWS Service Access | Via Private or NAT | Via AWS Backbone |
| Authentication | IAM Roles | IAM Roles |
| Encryption | TLS | TLS |
| Logging | CloudWatch | CloudWatch |
| Cost | $70/month | $0 |

---

## 🚀 Implementation Steps

### Step 1: Update AFT Terraform Configuration

```bash
cd /Users/ravish_sankhyan-guva/Devops-Sre-Aft/MCK-aft/learn-terraform-aws-control-tower-aft
```

**File: `main.tf`**
```terraform
module "aft" {
  source = "./local-aft-module"
  
  # Core Configuration
  ct_management_account_id    = var.ct_management_account_id
  log_archive_account_id      = var.log_archive_account_id
  audit_account_id            = var.audit_account_id
  aft_management_account_id   = var.aft_management_account_id
  ct_home_region              = var.ct_home_region
  tf_backend_secondary_region = var.tf_backend_secondary_region

  # 💰 DISABLE VPC to eliminate NAT Gateway costs (~$840/year savings)
  aft_enable_vpc = false

  # VCS Configuration
  vcs_provider                                  = "github"
  account_request_repo_name                     = "${var.github_username}/learn-terraform-aft-account-request"
  account_provisioning_customizations_repo_name = "${var.github_username}/learn-terraform-aft-account-provisioning-customizations"
  global_customizations_repo_name               = "${var.github_username}/learn-terraform-aft-global-customizations"
  account_customizations_repo_name              = "${var.github_username}/learn-terraform-aft-account-customizations"
}
```

### Step 2: Verify Local Module

```bash
# Ensure local module is present
ls -la local-aft-module/

# Check that aft_enable_vpc variable exists
grep -A 5 "aft_enable_vpc" local-aft-module/variables.tf
```

### Step 3: Plan Terraform Changes

```bash
terraform plan -out=no-nat.tfplan
```

**Expected Changes:**
- CodeBuild projects will be updated (vpc_config removed)
- VPC, Subnets, NAT Gateways, Route Tables remain (can be deleted manually later)
- No disruption to existing accounts

### Step 4: Apply Changes

```bash
# Apply the configuration
terraform apply no-nat.tfplan

# This updates CodeBuild projects to remove VPC configuration
```

### Step 5: Test Account Provisioning

```bash
# Trigger a test account creation via GitHub Actions
# OR manually trigger the pipeline

# Monitor CodeBuild logs
aws logs tail /aws/codebuild/ct-aft-account-request \
  --since 5m \
  --follow \
  --region ap-south-1
```

### Step 6: Clean Up Old NAT Gateways (After Testing)

```bash
# Once confirmed working, delete NAT Gateways
aws ec2 delete-nat-gateway \
  --nat-gateway-id nat-0b523f36f5a3b2a7d \
  --region ap-south-1

aws ec2 delete-nat-gateway \
  --nat-gateway-id nat-0a3b32c9efc6895e4 \
  --region ap-south-1

# Wait 5 minutes, then release Elastic IPs
sleep 300

aws ec2 describe-addresses \
  --filters "Name=domain,Values=vpc" \
  --query 'Addresses[?AssociationId==`null`].AllocationId' \
  --output text \
  --region ap-south-1 | \
  xargs -I {} aws ec2 release-address --allocation-id {} --region ap-south-1
```

---

## 📊 Cost Analysis

### Before (With NAT Gateway):

| Resource | Quantity | Unit Cost | Monthly | Annual |
|----------|----------|-----------|---------|--------|
| NAT Gateway | 2 | $32.40 | $64.80 | $777.60 |
| Data Processing | 100 GB | $0.045/GB | $4.50 | $54.00 |
| Elastic IP (attached) | 2 | $0.00 | $0.00 | $0.00 |
| **TOTAL** | | | **$69.30** | **$831.60** |

### After (No VPC):

| Resource | Quantity | Unit Cost | Monthly | Annual |
|----------|----------|-----------|---------|--------|
| **TOTAL** | | | **$0.00** | **$0.00** |

**💰 Annual Savings: $831.60**

---

## ⚙️ AFT Components Affected

### CodeBuild Projects (All Updated):
1. `ct-aft-account-request`
2. `aft-account-provisioning-customizations-terraform`
3. `aft-global-customizations-terraform`
4. `aft-account-customizations-terraform-v2`
5. `aft-create-pipeline-v2`

### Components Unchanged:
- ✅ DynamoDB tables
- ✅ Step Functions
- ✅ Lambda functions
- ✅ Service Catalog
- ✅ EventBridge rules
- ✅ CodePipelines
- ✅ IAM roles

---

## 🔄 Data Flow Without NAT Gateway

### Account Request Flow:

```
Developer
   │
   └─► Push to GitHub (learn-terraform-aft-account-request)
         │
         └─► EventBridge/Webhook triggers CodePipeline
               │
               └─► CodePipeline: Source stage (GitHub)
                     │
                     └─► CodePipeline: Build stage
                           │
                           └─► CodeBuild (No VPC)
                                 │
                                 ├─► Internet: Clone GitHub repo
                                 ├─► Internet: Download Terraform
                                 ├─► Internet: pip install packages
                                 ├─► AWS: Read SSM parameters
                                 ├─► AWS: Assume IAM roles
                                 ├─► AWS: terraform init (S3 backend)
                                 ├─► AWS: terraform apply
                                 └─► AWS: Write to DynamoDB
                                       │
                                       └─► DynamoDB Stream
                                             │
                                             └─► Lambda trigger
                                                   │
                                                   └─► SQS message
                                                         │
                                                         └─► Service Catalog
                                                               │
                                                               └─► Control Tower
                                                                     │
                                                                     └─► Create Vended Account
```

**All without NAT Gateway costs!**

---

## 🎯 Benefits Summary

### Cost Benefits:
- ✅ **$831/year saved** (NAT Gateway + data transfer)
- ✅ **$0 ongoing network costs**
- ✅ No Elastic IP costs
- ✅ No cross-AZ data transfer costs

### Operational Benefits:
- ✅ **Simpler architecture** (fewer moving parts)
- ✅ **Faster builds** (no VPC attachment overhead)
- ✅ **No NAT Gateway health monitoring** needed
- ✅ **No VPC maintenance**
- ✅ **Easier troubleshooting** (no network layer complexity)

### Performance Benefits:
- ✅ **Same latency** for AWS services (AWS backbone)
- ✅ **Potentially faster** GitHub/internet access (AWS's direct routes)
- ✅ **No ENI attachment delay** for CodeBuild

### Security:
- ✅ **Same IAM-based security**
- ✅ **Same encryption** (TLS everywhere)
- ✅ **Same audit logging** (CloudWatch)
- ✅ **No additional attack surface** (no VPC to misconfigure)

---

## ⚠️ Considerations & Limitations

### When NAT Gateway IS Required:
1. **Private data sources:** If CodeBuild needs to access on-premises databases via VPN
2. **Custom network filtering:** If organization requires network-level egress filtering
3. **Compliance requirements:** If regulatory requirements mandate private subnets
4. **VPC peering scenarios:** If accessing resources in peered VPCs

### When NAT Gateway is NOT Required (Your Case):
- ✅ Standard AFT deployment
- ✅ Public GitHub repositories
- ✅ Public Terraform registries
- ✅ AWS service access only
- ✅ No hybrid cloud connectivity needed

---

## 🧪 Testing Checklist

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

---

## 📈 Monitoring

### Key Metrics to Watch:

1. **CodeBuild Success Rate:**
   ```bash
   aws codebuild batch-get-projects \
     --names ct-aft-account-request \
     --query 'projects[0].badge.badgeEnabled'
   ```

2. **Build Duration:**
   - Should remain same or improve (no VPC overhead)

3. **Pipeline Success Rate:**
   - Monitor in CodePipeline console

4. **Account Provisioning Time:**
   - Should be unchanged

---

## 🔄 Rollback Plan

If issues occur:

```terraform
# In main.tf, change:
aft_enable_vpc = false

# Back to:
aft_enable_vpc = true

# Then apply:
terraform apply

# This will recreate NAT Gateways and VPC configuration
```

**Rollback Time:** 10-15 minutes
**Risk:** Low (easy to revert)

---

## 📚 Additional Resources

### AFT Documentation:
- [AWS AFT Guide](https://docs.aws.amazon.com/controltower/latest/userguide/aft-overview.html)
- [CodeBuild VPC Support](https://docs.aws.amazon.com/codebuild/latest/userguide/vpc-support.html)

### Cost Optimization:
- [AWS NAT Gateway Pricing](https://aws.amazon.com/vpc/pricing/)
- [CodeBuild Pricing](https://aws.amazon.com/codebuild/pricing/)

---

## ✅ Summary

**Architecture Decision:** Run CodeBuild **without VPC configuration**

**Rationale:**
- 💰 Eliminates $831/year in NAT Gateway costs
- 🚀 Maintains full AFT functionality
- 🔐 Preserves security (IAM-based)
- ⚡ Potentially improves performance
- 🎯 Simpler architecture

**Implementation Complexity:** Low (10-15 minutes)
**Risk:** Low (easy rollback)
**Savings:** High ($831/year)

**Recommendation:** ⭐⭐⭐⭐⭐ **Highly Recommended** for this use case

---

**Last Updated:** December 8, 2025  
**Author:** AFT Implementation Team  
**Status:** Ready for Implementation
