variable "environment" {
  description = "The environment name"
  type        = string
}

variable "bucket_name" {
  description = "The S3 bucket name Lambda needs access to"
  type        = string
}