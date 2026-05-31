output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.email_assistant.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.email_assistant.arn
}

output "lambda_invoke_arn" {
  description = "The invoke ARN of the Lambda function"
  value       = aws_lambda_function.email_assistant.invoke_arn
}

output "dlq_arn" {
  description = "The ARN of the Lambda DLQ"
  value       = aws_sqs_queue.lambda_dlq.arn
}

output "kms_key_arn" {
  description = "The ARN of the KMS key"
  value       = aws_kms_key.email_assistant.arn
}