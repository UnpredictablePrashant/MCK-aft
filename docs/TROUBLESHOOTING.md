# AFT Troubleshooting Guide

## Why Don't I See Account Requests Being Processed?

This document explains the common IAM permission issues encountered during AFT setup and how they were resolved.

### Summary of Issues Fixed

During the AFT deployment testing, we encountered a chain of IAM permission issues. Here's what was fixed:

#### 1. Lambda → AWSAFTExecution-v2 AssumeRole Permission
**Error:**
```
User: arn:aws:sts::809574937450:assumed-role/aft-lambda-account-request-processor/...
is not authorized to perform: sts:AssumeRole on resource: 
arn:aws:iam::809574937450:role/AWSAFTExecution-v2
```

**Fix:** Updated `AWSAFTExecution-v2` trust policy to allow Lambda execution roles:
```json
{
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::809574937450:role/aft-lambda-account-request-processor"
  },
  "Action": "sts:AssumeRole"
}
```

#### 2. KMS Decrypt Permission (DynamoDB Stream)
**Error:**
```
User is not authorized to perform: dynamodb:DescribeStream ... 
because no identity-based policy allows the dynamodb:DescribeStream action
```

**Fix:** Added DynamoDB Stream permissions to Lambda role:
```json
{
  "Effect": "Allow",
  "Action": [
    "dynamodb:DescribeStream",
    "dynamodb:GetRecords",
    "dynamodb:GetShardIterator",
    "dynamodb:ListStreams"
  ],
  "Resource": "arn:aws:dynamodb:ap-south-1:809574937450:table/aft-request/stream/*"
}
```

#### 3. KMS Decrypt Permission (Encrypted Streams)
**Error:**
```
User is not authorized to perform: kms:Decrypt on resource: 
arn:aws:kms:ap-south-1:809574937450:key/... 
because no identity-based policy allows the kms:Decrypt action
```

**Fix:** Added KMS decrypt permission:
```json
{
  "Effect": "Allow",
  "Action": [
    "kms:Decrypt",
    "kms:DescribeKey"
  ],
  "Resource": "*"
}
```

#### 4. SSM Parameter Read Permission
**Error:**
```
User is not authorized to perform: ssm:GetParameter on resource: 
arn:aws:ssm:ap-south-1:809574937450:parameter/aft/account/aft-management/account-id
```

**Fix:** Added SSM read permissions:
```json
{
  "Effect": "Allow",
  "Action": [
    "ssm:GetParameter",
    "ssm:GetParameters"
  ],
  "Resource": "arn:aws:ssm:ap-south-1:809574937450:parameter/aft/*"
}
```

#### 5. Cross-Account Trust Policy (CT Management)
**Error:**
```
User: arn:aws:sts::809574937450:assumed-role/AWSAFTExecution-v2/AWSAFT-Session 
is not authorized to perform: sts:AssumeRole on resource: 
arn:aws:iam::535355705679:role/AWSAFTExecution-v2
```

**Fix:** Updated trust policy in CT Management account (535355705679):
```json
{
  "Effect": "Allow",
  "Principal": {
    "AWS": [
      "arn:aws:iam::809574937450:root",
      "arn:aws:iam::809574937450:role/AWSAFTExecution-v2",
      "arn:aws:iam::809574937450:role/AWSAFTService-v2"
    ]
  },
  "Action": "sts:AssumeRole"
}
```

#### 6. KMS GenerateDataKey Permission (SQS Encryption)
**Error:**
```
User is not authorized to perform: kms:GenerateDataKey on resource: 
arn:aws:kms:ap-south-1:809574937450:key/... 
because no identity-based policy allows the kms:GenerateDataKey action
```

**Fix:** Added KMS GenerateDataKey permission for encrypting SQS messages:
```json
{
  "Effect": "Allow",
  "Action": [
    "kms:Decrypt",
    "kms:DescribeKey",
    "kms:GenerateDataKey"
  ],
  "Resource": "*"
}
```

---

## DynamoDB Stream Event Source Mapping Issues

### Issue: StartingPosition set to LATEST

The Event Source Mapping was configured with `StartingPosition: LATEST`, which means it only processes NEW events going forward, not existing ones in the stream.

**Solution:** After fixing all IAM permissions, create a fresh account request to trigger a new DynamoDB INSERT event.

### Issue: Event Source Mapping Stuck in Error State

Sometimes the mapping gets stuck in a retry loop with old cached permissions.

**Solution:** Disable and re-enable the Event Source Mapping:
```bash
# Get mapping UUID
MAPPING_UUID=$(aws lambda list-event-source-mappings \
  --region ap-south-1 \
  --query 'EventSourceMappings[?contains(FunctionArn, `action-trigger`)]|[0].UUID' \
  --output text)

# Disable
aws lambda update-event-source-mapping \
  --uuid "$MAPPING_UUID" \
  --no-enabled \
  --region ap-south-1

# Wait 10 seconds
sleep 10

# Re-enable
aws lambda update-event-source-mapping \
  --uuid "$MAPPING_UUID" \
  --enabled \
  --region ap-south-1
```

---

## Complete Lambda IAM Policy (Final Working Version)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole",
        "sqs:SendMessage",
        "dynamodb:UpdateItem",
        "sns:Publish"
      ],
      "Resource": [
        "arn:aws:iam::809574937450:role/AWSAFTAdmin",
        "arn:aws:iam::809574937450:role/AWSAFTExecution-v2",
        "arn:aws:iam::809574937450:role/AWSAFTService-v2",
        "arn:aws:dynamodb:ap-south-1:809574937450:table/aft-request",
        "arn:aws:sqs:ap-south-1:809574937450:aft-account-request-v2.fifo",
        "arn:aws:sns:ap-south-1:809574937450:aft-notifications",
        "arn:aws:sns:ap-south-1:809574937450:aft-failure-notifications"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:DescribeStream",
        "dynamodb:GetRecords",
        "dynamodb:GetShardIterator",
        "dynamodb:ListStreams"
      ],
      "Resource": "arn:aws:dynamodb:ap-south-1:809574937450:table/aft-request/stream/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ],
      "Resource": "arn:aws:ssm:ap-south-1:809574937450:parameter/aft/*"
    }
  ]
}
```

---

## Monitoring Account Provisioning

### Quick Status Check

```bash
cd /Users/ravish_sankhyan-guva/Devops-Sre-Aft/MCK-aft
./scripts/check-account-status.sh
```

### Manual Checks

**Check SQS Queue:**
```bash
aws sqs get-queue-attributes \
  --queue-url https://sqs.ap-south-1.amazonaws.com/809574937450/aft-account-request-v2.fifo \
  --attribute-names ApproximateNumberOfMessages \
  --region ap-south-1
```

**Check Lambda Logs:**
```bash
# DynamoDB Stream Lambda
aws logs tail /aws/lambda/aft-account-request-action-trigger \
  --since 10m \
  --region ap-south-1

# Account Processor Lambda
aws logs tail /aws/lambda/aft-account-request-processor \
  --since 10m \
  --region ap-south-1
```

**Check Step Functions:**
```bash
STATE_MACHINE_ARN=$(aws stepfunctions list-state-machines \
  --region ap-south-1 \
  --query 'stateMachines[?contains(name, `aft-account-provisioning`)].stateMachineArn' \
  --output text)

aws stepfunctions list-executions \
  --state-machine-arn "$STATE_MACHINE_ARN" \
  --region ap-south-1
```

**Check AWS Organizations:**
```bash
aws organizations list-accounts \
  --query 'Accounts[?contains(Email, `ravish`)]'
```

---

## Expected Timeline

After all IAM permissions are fixed:

```
Time     | Event
---------|--------------------------------------------------
0:00     | Account request created in DynamoDB
0:00-2m  | DynamoDB Stream delivers event to Lambda
2:00     | Lambda processes event → sends to SQS
5:00     | EventBridge scheduler triggers account processor
5:00     | Account processor reads SQS → triggers Step Functions
10:00    | Step Functions starts account provisioning workflow
45-60m   | Account created in AWS Organizations ✅
```

---

## Common Issues

### "No messages pending processing" in SQS

**Cause:** DynamoDB Stream Lambda failed to send messages due to IAM permissions.

**Check:** Lambda logs for errors:
```bash
aws logs tail /aws/lambda/aft-account-request-action-trigger \
  --since 30m \
  --region ap-south-1 | grep ERROR
```

### "No Step Functions executions yet"

**Cause:** EventBridge scheduler hasn't triggered yet (runs every 5 minutes) or SQS queue is empty.

**Check:**
1. Verify messages in SQS queue
2. Check EventBridge rule is enabled
3. Wait for next 5-minute interval

### "Account not created yet"

**Cause:** Step Functions takes 30-45 minutes to provision accounts.

**Monitor:** Step Functions execution status:
```bash
aws stepfunctions list-executions \
  --state-machine-arn <STATE_MACHINE_ARN> \
  --status-filter RUNNING \
  --region ap-south-1
```

---

## Additional Resources

- **AFT Documentation**: https://docs.aws.amazon.com/controltower/latest/userguide/aft-overview.html
- **DynamoDB Streams**: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Streams.html
- **Lambda Event Source Mappings**: https://docs.aws.amazon.com/lambda/latest/dg/invocation-eventsourcemapping.html

---

**Last Updated:** 2025-12-08

