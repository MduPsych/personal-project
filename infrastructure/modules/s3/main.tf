terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_s3_bucket" "email_bucket" {
  bucket = "${var.environment}-${var.project_name}-emails-${var.aws_account_id}"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "email_bucket" {
  bucket = aws_s3_bucket.email_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "email_bucket" {
  bucket = aws_s3_bucket.email_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "email_bucket" {
  bucket = aws_s3_bucket.email_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "email_bucket" {
  bucket = aws_s3_bucket.email_bucket.id

  rule {
    id     = "email-retention"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}