import json
import logging
import os
import boto3
from typing import Any

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client("s3")
comprehend_client = boto3.client("comprehend")
bedrock_client = boto3.client("bedrock-runtime", region_name="us-east-1")

# Environment variables
BUCKET_NAME = os.environ.get("BUCKET_NAME")
ENVIRONMENT = os.environ.get("ENVIRONMENT")
MODEL_ID = "us.amazon.nova-micro-v1:0"


def get_email_from_s3(bucket: str, key: str) -> str:
    """Retrieve email content from S3."""
    try:
        response = s3_client.get_object(Bucket=bucket, Key=key)
        return response["Body"].read().decode("utf-8")
    except Exception as e:
        logger.error("Failed to retrieve email from S3: %s", str(e))
        raise


def analyse_sentiment(text: str) -> dict:
    """Analyse email sentiment using Comprehend."""
    try:
        response = comprehend_client.detect_sentiment(
            Text=text[:4500], LanguageCode="en"
        )
        return {
            "sentiment": response["Sentiment"],
            "scores": response["SentimentScore"],
        }
    except Exception as e:
        logger.error("Failed to analyse sentiment: %s", str(e))
        raise


def generate_reply(email_content: str, sentiment: str) -> str:
    """Generate email reply suggestion using Bedrock."""
    prompt = f"""You are a professional email assistant.
    Email content: {email_content}
    Detected sentiment: {sentiment}

    Generate a professional reply to this email.
    Keep it concise and appropriate to the sentiment."""

    try:
        response = bedrock_client.converse(
            modelId=MODEL_ID, messages=[{"role": "user", "content": [{"text": prompt}]}]
        )
        return response["output"]["message"]["content"][0]["text"]
    except Exception as e:
        logger.error("Failed to generate reply: %s", str(e))
        raise


def lambda_handler(event: dict, context: Any) -> dict:
    """Main Lambda handler."""
    logger.info("Processing event in environment: %s", ENVIRONMENT)

    try:
        # Extract S3 details from event
        bucket = event.get("bucket", BUCKET_NAME)
        key = event.get("key")

        if not key:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Missing email key"}),
            }
        if not bucket:
            return {
            "statusCode": 400,
            "body": json.dumps({"error": "Missing bucket name"})
            }
        # Get email from S3
        email_content = get_email_from_s3(bucket, key)
        logger.info("Successfully retrieved email from S3")

        # Analyse sentiment
        sentiment_result = analyse_sentiment(email_content)
        logger.info("Sentiment analysis complete: %s", sentiment_result["sentiment"])

        # Generate reply
        reply = generate_reply(email_content, sentiment_result["sentiment"])
        logger.info("Reply generated successfully")

        return {
            "statusCode": 200,
            "body": json.dumps(
                {
                    "sentiment": sentiment_result["sentiment"],
                    "sentiment_scores": sentiment_result["scores"],
                    "suggested_reply": reply,
                    "environment": ENVIRONMENT,
                }
            ),
        }

    except Exception as e:
        logger.error("Lambda execution failed: %s", str(e))
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
