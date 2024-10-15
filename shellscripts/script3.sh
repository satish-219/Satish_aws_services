#!/bin/bash

# Variables
AMI_UBUNTU="ami-0522ab6e1ddcc7055"  
AMI_REDHAT="ami-022ce6f32988af5fa"  
INSTANCE_TYPE="t2.micro"
KEY_NAME="satish"                  
SECURITY_GROUP="sg-01573d594e53ce88c"

# Start Ubuntu instance
UBUNTU_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_UBUNTU \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-groups $SECURITY_GROUP \
    --query "Instances[0].InstanceId" \
    --output text)

echo "Started Ubuntu instance with ID:i-0c3b6e728a0dc029e"

# Start Red Hat instance
REDHAT_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_REDHAT \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-groups $SECURITY_GROUP \
    --query "Instances[0].InstanceId" \
    --output text)

echo "Started Red Hat instance with ID:i-044acc0ed1d1d90af"

# Wait for the instances to be in a running state
echo "Waiting for instances to be in 'running' state..."
aws ec2 wait instance-running --instance-ids $UBUNTU_INSTANCE_ID $REDHAT_INSTANCE_ID

# Get the private IP addresses
UBUNTU_IP=$(aws ec2 describe-instances \
    --instance-ids $UBUNTU_INSTANCE_ID \
    --query "Reservations[0].Instances[0] 172.31.0.61" \
    --output text)

REDHAT_IP=$(aws ec2 describe-instances \
    --instance-ids $REDHAT_INSTANCE_ID \
    --query "Reservations[0].Instances[0] 172.31.33.94" \
    --output text)

echo "Ubuntu Instance Private IP: $UBUNTU_IP"
echo "Red Hat Instance Private IP: $REDHAT_IP"

# List all running instances and their private IPs
echo "Listing all running instances and their private IPs..."
aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running" \
    --query "Reservations[].Instances[].{Instance:InstanceId,PrivateIP:PrivateIpAddress}" \
    --output table
