terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_kms_key" "email_assistant" {
  description             = "${var.environment}-email-assistant-key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Environment = var.environment
    Project     = "email-assistant"
  }
}

resource "aws_kms_alias" "email_assistant" {
  name          = "alias/${var.environment}-email-assistant"
  target_key_id = aws_kms_key.email_assistant.key_id
}

resource "aws_sqs_queue" "lambda_dlq" {
  name                      = "${var.environment}-email-assistant-dlq"
  message_retention_seconds = 1209600
  kms_master_key_id         = aws_kms_key.email_assistant.key_id

  tags = {
    Environment = var.environment
    Project     = "email-assistant"
  }
}

resource "aws_cloudwatch_log_group" "email_assistant" {
  name              = "/aws/lambda/${var.environment}-email-assistant"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.email_assistant.arn

  tags = {
    Environment = var.environment
    Project     = "email-assistant"
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

  reserved_concurrent_executions = var.reserved_concurrency

  kms_key_arn = aws_kms_key.email_assistant.arn

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

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

  depends_on = [aws_cloudwatch_log_group.email_assistant]
}

resource "aws_lambda_function_event_invoke_config" "email_assistant" {
  function_name          = aws_lambda_function.email_assistant.function_name
  maximum_retry_attempts = 1
}