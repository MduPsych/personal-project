terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_caller_identity" "current" {}

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

resource "aws_kms_key" "email_assistant" {
  description             = "${var.environment}-email-assistant-key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.environment}-email-assistant"
          }
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = "email-assistant"
  }
}

resource "aws_lambda_function_event_invoke_config" "email_assistant" {
  function_name          = aws_lambda_function.email_assistant.function_name
  maximum_retry_attempts = 1
}