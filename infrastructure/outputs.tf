output "bucket_name" {
  description = "The email S3 bucket name"
  value       = module.s3.bucket_name
}

output "lambda_function_name" {
  description = "The Lambda function name"
  value       = module.lambda.lambda_function_name
}

output "lambda_function_arn" {
  description = "The Lambda function ARN"
  value       = module.lambda.lambda_function_arn
}

output "lambda_role_arn" {
  description = "The Lambda IAM role ARN"
  value       = module.iam.lambda_role_arn
}