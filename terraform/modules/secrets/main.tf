# Terraform creates the secret but never its value. Values are written once
# with the AWS CLI (docs/runbook.md), so they never appear in Terraform state
# or in the repository.

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

data "aws_iam_policy_document" "this_key" {
  #checkov:skip=CKV_AWS_111:Standard KMS key policy root statement
  #checkov:skip=CKV_AWS_109:Standard KMS key policy root statement
  #checkov:skip=CKV_AWS_356:Resource "*" in a key policy refers to the key itself
  statement {
    sid       = "AccountAdmin"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_kms_key" "this" {
  description             = "Encrypts ${var.name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.this_key.json
}

resource "aws_kms_alias" "this" {
  name          = "alias/${replace(var.name, "/", "-")}"
  target_key_id = aws_kms_key.this.key_id
}

resource "aws_secretsmanager_secret" "this" {
  name                    = var.name
  description             = "API keys for the LLM gateway (GATEWAY_API_KEY, OPENAI_API_KEY)"
  kms_key_id              = aws_kms_key.this.arn
  recovery_window_in_days = 7
}

# The External Secrets Operator controller reads the secret through EKS Pod
# Identity, with a role that can read this one secret and nothing else. Pod
# Identity applies to the controller's own service account, so the gateway
# pods themselves never hold AWS credentials.
module "reader" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.7"

  name = "${replace(var.name, "/", "-")}-reader"

  attach_external_secrets_policy        = true
  external_secrets_secrets_manager_arns = concat([aws_secretsmanager_secret.this.arn], var.additional_secret_arns)
  external_secrets_kms_key_arns         = [aws_kms_key.this.arn]
  external_secrets_create_permission    = false

  associations = {
    controller = {
      cluster_name    = var.cluster_name
      namespace       = var.namespace
      service_account = var.service_account
    }
  }
}
