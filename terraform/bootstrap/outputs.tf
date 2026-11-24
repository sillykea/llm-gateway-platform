output "state_bucket" {
  description = "Use as the bucket in each stack's backend config."
  value       = aws_s3_bucket.state.bucket
}

output "state_kms_key_arn" {
  description = "KMS key that encrypts state."
  value       = aws_kms_key.state.arn
}

output "plan_role_arn" {
  description = "Set as the AWS_PLAN_ROLE_ARN repository variable."
  value       = aws_iam_role.plan.arn
}

output "apply_role_arns" {
  description = "Set as AWS_APPLY_ROLE_ARN in each GitHub environment."
  value       = { for env, role in aws_iam_role.apply : env => role.arn }
}
