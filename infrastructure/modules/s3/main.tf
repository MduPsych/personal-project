terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "s3_key" {
  description             = "${var.environment}-email-assistant-s3-key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_kms_alias" "s3_key" {
  name          = "alias/${var.environment}-email-assistant-s3"
  target_key_id = aws_kms_key.s3_key.key_id
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
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_key.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "email_bucket" {
  bucket = aws_s3_bucket.email_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "email_bucket" {
  bucket        = aws_s3_bucket.email_bucket.id
  target_bucket = aws_s3_bucket.email_bucket.id
  target_prefix = "access-logs/"
}

resource "aws_s3_bucket_notification" "email_bucket" {
  bucket = aws_s3_bucket.email_bucket.id
}

resource "aws_s3_bucket_lifecycle_configuration" "email_bucket" {
  bucket = aws_s3_bucket.email_bucket.id

  rule {
    id     = "email-retention"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

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

resource "aws_s3_bucket_replication_configuration" "email_bucket" {
  bucket = aws_s3_bucket.email_bucket.id
  role   = aws_iam_role.replication_role.arn

  rule {
    id     = "email-replication"
    status = "Enabled"

    filter {}

    delete_marker_replication {
      status = "Enabled"
    }

    destination {
      bucket        = "arn:aws:s3:::${var.environment}-${var.project_name}-emails-replica-${var.aws_account_id}"
      storage_class = "STANDARD_IA"

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.s3_key.arn
      }
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.email_bucket]
}

resource "aws_iam_role" "replication_role" {
  name = "${var.environment}-${var.project_name}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy" "replication_policy" {
  name = "${var.environment}-${var.project_name}-s3-replication-policy"
  role = aws_iam_role.replication_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.email_bucket.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.email_bucket.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTag"
        ]
        Resource = "arn:aws:s3:::${var.environment}-${var.project_name}-emails-replica-${var.aws_account_id}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = aws_kms_key.s3_key.arn
      }
    ]
  })
}

resource "aws_s3_bucket" "replica_bucket" {
  bucket = "${var.environment}-${var.project_name}-emails-replica-${var.aws_account_id}"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "replica_bucket" {
  bucket = aws_s3_bucket.replica_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "replica_bucket" {
  bucket = aws_s3_bucket.replica_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_key.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "replica_bucket" {
  bucket = aws_s3_bucket.replica_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}