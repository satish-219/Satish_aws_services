#!/bin/bash

# Specify the region
REGION="ap-south-1"

# Retrieve all running instances
INSTANCE_IDS=$(aws ec2 describe-instances \
    --region $REGION \
    --filters "Name=instance-state-name,Values=running" \
    --query "Reservations[].Instances[].InstanceId" --output text)

# Check if there are any running instances
if [ -z "$INSTANCE_IDS" ]; then
    echo "No running instances found."
else
    # Stop all running instances
    echo "Stopping instances: $INSTANCE_IDS"
    aws ec2 stop-instances --instance-ids $INSTANCE_IDS --region $REGION
fi

# check if there are any stopped instances
INSTANCE_IDS=$(aws ec2 describe-instances \
    --region $REGION \
    --filters "Name=instance-state-name,Values=stopped" \
    --query "Reservations[].Instances[].InstanceId" --output text)

if [ -z "$INSTANCE_IDS" ]; then
    echo "No running instances found."
else
    # start all running instances
    echo "Start instances: $INSTANCE_IDS"
    aws ec2 start-instances --instance-ids $INSTANCE_IDS --region $REGION
fi
