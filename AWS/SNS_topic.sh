#!/bin/bash

# Variables
SNS_TOPIC_NAME="sample_sns_topic"
SQS_QUEUE_NAME="sample_queue"
EMAIL_ADDRESS="satishbaburavuri@gmail.com"

# Create SNS Topic
echo "Creating SNS Topic..."
SNS_TOPIC_ARN=$(aws sns create-topic --name $SNS_TOPIC_NAME --query 'TopicArn' --output text)
echo "SNS Topic created: $SNS_TOPIC_ARN"

# Subscribe Email to the SNS Topic
echo "Subscribing email $EMAIL_ADDRESS to the SNS Topic..."
aws sns subscribe --topic-arn $SNS_TOPIC_ARN --protocol email --notification-endpoint $EMAIL_ADDRESS
echo "Subscription request sent to email: $EMAIL_ADDRESS"
echo "Please confirm the subscription from the email to proceed."

# Wait for user to confirm the email subscription
read -p "Press [Enter] after confirming the email subscription..."

# Create SQS Queue
echo "Creating SQS Queue..."
SQS_QUEUE_URL=$(aws sqs create-queue --queue-name $SQS_QUEUE_NAME --query 'QueueUrl' --output text)
SQS_QUEUE_ARN=$(aws sqs get-queue-attributes --queue-url $SQS_QUEUE_URL --attribute-name QueueArn --query 'Attributes.QueueArn' --output text)
echo "SQS Queue created: $SQS_QUEUE_URL"

# Subscribe SQS Queue to SNS Topic
echo "Subscribing SQS Queue to SNS Topic..."
aws sns subscribe --topic-arn $SNS_TOPIC_ARN --protocol sqs --notification-endpoint $SQS_QUEUE_ARN
echo "SQS Queue subscribed to SNS Topic."

# Send a test message to the SNS Topic
echo "Sending a test message to the SNS Topic..."
aws sns publish --topic-arn $SNS_TOPIC_ARN --message "This is a test message from SNS to SQS"
echo "Test message sent."

# Receive the message from the SQS Queue
echo "Receiving messages from the SQS Queue..."
MESSAGES=$(aws sqs receive-message --queue-url $SQS_QUEUE_URL --max-number-of-messages 1 --wait-time-seconds 10)

if [ -z "$MESSAGES" ]; then
    echo "No messages received. Please check the SQS queue and SNS topic configuration."
else
    echo "Message received from SQS Queue:"
    echo $MESSAGES
fi


