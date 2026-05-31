variable "environment" {
  description = "The environment name"
  type        = string
}

variable "project_name" {
  description = "The project name"
  type        = string
  default     = "email-assistant"
}

variable "aws_account_id" {
  description = "AWS account ID for unique bucket naming"
  type        = string
}