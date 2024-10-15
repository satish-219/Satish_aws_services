#!/bin/bash

# Set variables
REGION="ap-south-1"      
VPC_CIDR="10.0.0.0/16"
PUBLIC_SUBNET_CIDR=("10.0.1.0/24" "10.0.2.0/24" "10.0.3.0/24")
PRIVATE_SUBNET_CIDR=("10.0.4.0/24" "10.0.5.0/24" "10.0.6.0/24")
AMI_ID="ami-04a37924ffe27da53"
INSTANCE_TYPE="t2.micro"
KEY_NAME="satish.pem"

# Create a VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --region $REGION --query 'Vpc.VpcId' --output text)
echo "VPC is Created with the ID: $VPC_ID"

# Create Subnets
#public-subnets
for i in {0..2}; do
  PUBLIC_SUBNET_ID[i]=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block ${PUBLIC_SUBNET_CIDR[i]} --availability-zone ${REGION}a --query 'Subnet.SubnetId' --output text)
  echo "Public Subnet ${i} is created with ID: ${PUBLIC_SUBNET_ID[i]}"
done

#private-subnets
for i in {0..2}; do
  PRIVATE_SUBNET_ID[i]=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block ${PRIVATE_SUBNET_CIDR[i]} --availability-zone ${REGION}b --query 'Subnet.SubnetId' --output text)
  echo "Private Subnet ${i} is created with ID: ${PRIVATE_SUBNET_ID[i]}"
done

# Create and Attach Internet Gateway (IGW)
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID
echo "Internet Gateway is Created and Attached with ID: $IGW_ID"

# Create Route Tables
PUBLIC_ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
PRIVATE_ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
echo "Route Tables are Created. Public: $PUBLIC_ROUTE_TABLE_ID, Private: $PRIVATE_ROUTE_TABLE_ID"

# Add Routes to Route Tables
aws ec2 create-route --route-table-id $PUBLIC_ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
echo "Route added to Public Route Table to allow Internet access"

# Associate Public Subnets with Public Route Table
for SUBNET_ID in ${PUBLIC_SUBNET_ID[@]}; do
  aws ec2 associate-route-table --route-table-id $PUBLIC_ROUTE_TABLE_ID --subnet-id $SUBNET_ID
done
echo "Public Subnets associated with Public Route Table"

# Create NAT Gateway (NGW) with Elastic IP
EIP_ALLOC_ID=$(aws ec2 allocate-address --query 'AllocationId' --output text)
NGW_ID=$(aws ec2 create-nat-gateway --subnet-id ${PUBLIC_SUBNET_ID[0]} --allocation-id $EIP_ALLOC_ID --query 'NatGateway.NatGatewayId' --output text)
echo "NAT Gateway Created with ID: $NGW_ID"

# Wait for NGW to become available
aws ec2 wait nat-gateway-available --nat-gateway-ids $NGW_ID
echo "NAT Gateway is now available"

# Add Routes to Private Route Table
aws ec2 create-route --route-table-id $PRIVATE_ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NGW_ID
echo "Route added to Private Route Table to send traffic through NAT Gateway"

# Associate Private Subnets with Private Route Table
for SUBNET_ID in ${PRIVATE_SUBNET_ID[@]}; do
  aws ec2 associate-route-table --route-table-id $PRIVATE_ROUTE_TABLE_ID --subnet-id $SUBNET_ID
done
echo "Private Subnets associated with Private Route Table"

# Launch EC2 Instance in Public Subnet
PUBLIC_INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --subnet-id ${PUBLIC_SUBNET_ID[0]} --query 'Instances[0].InstanceId' --output text)
echo "EC2 Instance Launched in Public Subnet with ID: $PUBLIC_INSTANCE_ID"

# Launch EC2 Instance in Private Subnet
PRIVATE_INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --subnet-id ${PRIVATE_SUBNET_ID[0]} --query 'Instances[0].InstanceId' --output text)
echo "EC2 Instance Launched in Private Subnet with ID: $PRIVATE_INSTANCE_ID"

# Wait for both instances to be running
aws ec2 wait instance-running --instance-ids $PUBLIC_INSTANCE_ID $PRIVATE_INSTANCE_ID

# Stop both instances
aws ec2 stop-instances --instance-ids $PUBLIC_INSTANCE_ID $PRIVATE_INSTANCE_ID
echo "Stopped both EC2 Instances"

