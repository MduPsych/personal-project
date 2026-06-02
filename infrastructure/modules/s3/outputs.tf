output "bucket_name" {
  description = "The name of the email S3 bucket"
  value       = aws_s3_bucket.email_bucket.id
}

output "bucket_arn" {
  description = "The ARN of the email S3 bucket"
  value       = aws_s3_bucket.email_bucket.arn
}

output "kms_key_arn" {
  description = "The ARN of the S3 KMS key"
  value       = aws_kms_key.s3_key.arn
}