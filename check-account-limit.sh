#!/bin/bash

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 CHECKING AWS ACCOUNT LIMITS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get current account count
CURRENT_COUNT=$(aws organizations list-accounts --query 'Accounts[].Id' --output text 2>/dev/null | wc -w | tr -d ' ')

if [ -n "$CURRENT_COUNT" ]; then
  echo "📊 Current Accounts: $CURRENT_COUNT"
  echo ""
  
  # Check quota
  QUOTA=$(aws service-quotas get-service-quota \
    --service-code organizations \
    --quota-code L-29A0C5DF \
    --query 'Quota.Value' \
    --output text 2>/dev/null)
  
  if [ -n "$QUOTA" ]; then
    echo "📈 Account Limit: $QUOTA"
    AVAILABLE=$((QUOTA - CURRENT_COUNT))
    echo "✅ Available Slots: $AVAILABLE"
    echo ""
    
    if [ $AVAILABLE -ge 115 ]; then
      echo "✅ SUCCESS! You have enough capacity for 115 new accounts!"
    else
      echo "⚠️  WARNING! You only have $AVAILABLE slots available!"
      echo "   You need 115 slots but only have $AVAILABLE"
      echo ""
      echo "   ACTION REQUIRED:"
      echo "   Request a limit increase from AWS Support"
      echo "   🔗 https://console.aws.amazon.com/support/home#/case/create"
    fi
  else
    echo "⚠️  Could not retrieve quota information"
    echo "   Check manually: Service Quotas → AWS Organizations"
  fi
else
  echo "❌ Unable to list accounts. Check your AWS credentials."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
