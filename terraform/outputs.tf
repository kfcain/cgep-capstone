output "api_url" {
  value       = "https://${aws_api_gateway_rest_api.intake.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.default.stage_name}/intake"
  description = "POST /intake endpoint."
}

output "intake_table" {
  value       = aws_dynamodb_table.intake.name
  description = "DynamoDB table holding patient submissions."
}

output "uploads_bucket" {
  value       = aws_s3_bucket.uploads.id
  description = "S3 bucket where intake attachments land."
}

output "lambda_function_name" {
  value = aws_lambda_function.intake.function_name
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "evidence_vault" {
  value       = aws_s3_bucket.evidence_vault.id
  description = "Object Lock evidence vault used by the capstone pipeline."
}

output "cloudtrail_name" {
  value       = aws_cloudtrail.capstone.name
  description = "Multi-region, log-file-validating CloudTrail trail."
}
