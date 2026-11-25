# Secrets for llm-gateway-console (docs/adr/0007). All three are read by the
# External Secrets controller through the same Pod Identity role as the
# gateway's secrets, and encrypted with the same customer-managed KMS key.

# Shared by the console and every gateway: gateways send it when they pull
# keys from the console's internal endpoint.
resource "random_password" "console_sync" {
  length  = 48
  special = false
}

# Signs the console's session cookies.
resource "random_password" "console_session" {
  length  = 48
  special = false
}

resource "aws_secretsmanager_secret" "console_sync" {
  name                    = "llm-gateway/${var.environment}/console-sync"
  description             = "CONSOLE_SYNC_TOKEN shared by the console and the gateways"
  kms_key_id              = module.secrets.kms_key_arn
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "console_sync" {
  secret_id     = aws_secretsmanager_secret.console_sync.id
  secret_string = jsonencode({ CONSOLE_SYNC_TOKEN = random_password.console_sync.result })
}

resource "aws_secretsmanager_secret" "console_session" {
  name                    = "llm-gateway/${var.environment}/console-session"
  description             = "CONSOLE_SESSION_SECRET for the console's session cookies"
  kms_key_id              = module.secrets.kms_key_arn
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "console_session" {
  secret_id     = aws_secretsmanager_secret.console_session.id
  secret_string = jsonencode({ CONSOLE_SESSION_SECRET = random_password.console_session.result })
}

# Console sign-ins. Terraform creates the secret but never its value: the
# password hashes are written once with the AWS CLI (docs/runbook.md), so they
# never appear in Terraform state or in the repository.
resource "aws_secretsmanager_secret" "console_users" {
  name                    = "llm-gateway/${var.environment}/console-users"
  description             = "users.json for the console (username, role, password hash)"
  kms_key_id              = module.secrets.kms_key_arn
  recovery_window_in_days = 7
}
