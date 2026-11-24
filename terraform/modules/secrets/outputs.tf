output "secret_name" {
  value = aws_secretsmanager_secret.this.name
}

output "secret_arn" {
  value = aws_secretsmanager_secret.this.arn
}

output "kms_key_arn" {
  value = aws_kms_key.this.arn
}
