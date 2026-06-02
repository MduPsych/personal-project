variable "environment" {
  description = "The environment name"
  type        = string
}

variable "bucket_name" {
  description = "The S3 bucket name Lambda needs access to"
  type        = string
}
variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for Lambda"
  type        = string
}