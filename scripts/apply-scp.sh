#!/bin/bash
# Apply Service Control Policy to Restrict Expensive Services
# This script applies cost control SCPs to your AWS Organization

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🛡️  AWS SCP DEPLOYMENT - COST CONTROL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCP_FILE="$SCRIPT_DIR/../policies/scp/deny-expensive-services.json"

# Check if SCP file exists
if [ ! -f "$SCP_FILE" ]; then
    echo "❌ Error: SCP file not found at $SCP_FILE"
    exit 1
fi

export AWS_PROFILE=ct-mgmt
export AWS_DEFAULT_REGION=us-east-1

echo "📋 SCP Policy: Deny Expensive Services"
echo "   • Blocks: SageMaker, Redshift, EMR, large EC2 instances"
echo "   • Allows: t2/t3/t3a small instances, serverless services"
echo ""

# Check if policy already exists
EXISTING_POLICY=$(aws organizations list-policies \
    --filter SERVICE_CONTROL_POLICY \
    --query "Policies[?Name=='DenyExpensiveServices'].Id" \
    --output text 2>/dev/null || echo "")

if [ ! -z "$EXISTING_POLICY" ]; then
    echo "⚠️  Policy 'DenyExpensiveServices' already exists (ID: $EXISTING_POLICY)"
    echo ""
    read -p "Do you want to update it? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Updating existing policy..."
        aws organizations update-policy \
            --policy-id "$EXISTING_POLICY" \
            --content file://"$SCP_FILE"
        POLICY_ID="$EXISTING_POLICY"
        echo "✅ Policy updated!"
    else
        POLICY_ID="$EXISTING_POLICY"
        echo "Using existing policy..."
    fi
else
    echo "Creating new SCP policy..."
    POLICY_ID=$(aws organizations create-policy \
        --name "DenyExpensiveServices" \
        --description "Prevents use of expensive AWS services to control costs under $200/month" \
        --type SERVICE_CONTROL_POLICY \
        --content file://"$SCP_FILE" \
        --query 'Policy.PolicySummary.Id' \
        --output text)
    echo "✅ Policy created! ID: $POLICY_ID"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📌 ATTACH POLICY TO OUs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Select OUs to apply the cost control policy:"
echo ""
echo "1. LearnMck (ou-hn55-ambq41wc) - Recommended ✅"
echo "2. Sandbox (ou-hn55-8v2p3o33) - Recommended ✅"
echo "3. Batch14 (ou-hn55-97mt9432) - Recommended ✅"
echo "4. Batch15 (ou-hn55-si8zml39) - Recommended ✅"
echo "5. AFT-Lab-Rajesh (ou-hn55-j1275av7)"
echo "6. Security (ou-hn55-nk6je9rf)"
echo "7. Apply to ALL OUs (Root level) ⚠️"
echo "8. Skip attachment (manual later)"
echo ""
read -p "Enter your choice (1-8): " CHOICE

case $CHOICE in
    1)
        OU_ID="ou-hn55-ambq41wc"
        OU_NAME="LearnMck"
        ;;
    2)
        OU_ID="ou-hn55-8v2p3o33"
        OU_NAME="Sandbox"
        ;;
    3)
        OU_ID="ou-hn55-97mt9432"
        OU_NAME="Batch14"
        ;;
    4)
        OU_ID="ou-hn55-si8zml39"
        OU_NAME="Batch15"
        ;;
    5)
        OU_ID="ou-hn55-j1275av7"
        OU_NAME="AFT-Lab-Rajesh"
        ;;
    6)
        OU_ID="ou-hn55-nk6je9rf"
        OU_NAME="Security"
        ;;
    7)
        OU_ID="r-hn55"
        OU_NAME="Root (ALL OUs)"
        echo ""
        echo "⚠️  WARNING: This will affect ALL accounts in your organization!"
        read -p "Are you sure? (yes/no): " CONFIRM
        if [ "$CONFIRM" != "yes" ]; then
            echo "Aborted."
            exit 0
        fi
        ;;
    8)
        echo ""
        echo "✅ Policy created but not attached."
        echo ""
        echo "To attach later, use:"
        echo "aws organizations attach-policy \\"
        echo "  --policy-id $POLICY_ID \\"
        echo "  --target-id <OU_ID> \\"
        echo "  --profile ct-mgmt"
        exit 0
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo "Attaching policy to $OU_NAME..."

# Check if already attached
ATTACHED=$(aws organizations list-policies-for-target \
    --target-id "$OU_ID" \
    --filter SERVICE_CONTROL_POLICY \
    --query "Policies[?Id=='$POLICY_ID'].Id" \
    --output text 2>/dev/null || echo "")

if [ ! -z "$ATTACHED" ]; then
    echo "✅ Policy already attached to $OU_NAME"
else
    aws organizations attach-policy \
        --policy-id "$POLICY_ID" \
        --target-id "$OU_ID"
    echo "✅ Policy attached to $OU_NAME"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ SCP DEPLOYMENT COMPLETE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Summary:"
echo "   Policy ID: $POLICY_ID"
echo "   Applied to: $OU_NAME ($OU_ID)"
echo ""
echo "🧪 Test it:"
echo "   Try launching a large EC2 instance - it should be denied!"
echo ""
echo "📚 View details:"
echo "   aws organizations describe-policy --policy-id $POLICY_ID --profile ct-mgmt"
echo ""
echo "🗑️  To remove:"
echo "   aws organizations detach-policy --policy-id $POLICY_ID --target-id $OU_ID --profile ct-mgmt"
echo ""



