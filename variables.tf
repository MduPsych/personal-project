variable "environment" {
  description = "The environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
}

variable "project_name" {
  description = "The project name"
  type        = string
  default     = "email-assistant"
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