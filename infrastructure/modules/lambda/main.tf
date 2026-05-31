terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_lambda_function" "email_assistant" {
  function_name = "${var.environment}-email-assistant"
  role          = var.lambda_role_arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 256

  filename         = var.lambda_artifact_path
  source_code_hash = filebase64sha256(var.lambda_artifact_path)

  environment {
    variables = {
      ENVIRONMENT = var.environment
      BUCKET_NAME = var.bucket_name
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Environment = var.environment
    Project     = "email-assistant"
  }
}

resource "aws_cloudwatch_log_group" "email_assistant" {
  name              = "/aws/lambda/${var.environment}-email-assistant"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Project     = "email-assistant"
  }
}

resource "aws_lambda_function_event_invoke_config" "email_assistant" {
  function_name          = aws_lambda_function.email_assistant.function_name
  maximum_retry_attempts = 1
}