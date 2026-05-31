variable "environment" {
  description = "The environment name"
  type        = string
}

variable "lambda_role_arn" {
  description = "The ARN of the Lambda IAM role"
  type        = string
}

variable "bucket_name" {
  description = "The S3 bucket name for emails"
  type        = string
}

variable "lambda_artifact_path" {
  description = "Path to the Lambda ZIP artifact"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain Lambda logs"
  type        = number
  default     = 14
}