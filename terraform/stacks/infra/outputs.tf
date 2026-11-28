# Read by the platform stack through terraform_remote_state.

output "environment" {
  value = var.environment
}

output "region" {
  value = var.region
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "cluster_name" {
  value = module.cluster.cluster_name
}

output "cluster_endpoint" {
  value = module.cluster.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.cluster.cluster_certificate_authority_data
}

output "redis_address" {
  value = module.cache.address
}

output "secret_name" {
  value = module.secrets.secret_name
}

output "redis_secret_name" {
  value = module.cache.auth_secret_name
}

output "console_session_secret_name" {
  value = aws_secretsmanager_secret.console_session.name
}

output "console_sync_secret_name" {
  value = aws_secretsmanager_secret.console_sync.name
}

output "console_users_secret_name" {
  description = "Write users.json into this secret once (docs/runbook.md)."
  value       = aws_secretsmanager_secret.console_users.name
}

output "kubeconfig_command" {
  description = "Run this to point kubectl at the cluster."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.cluster.cluster_name}"
}

# GPU inference (docs/adr/0008). Karpenter's EC2NodeClass selects subnets and
# the node security group by ID, so nothing needs re-tagging.
output "gpu_inference_enabled" {
  value = var.enable_gpu_inference
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "node_security_group_id" {
  value = module.cluster.node_security_group_id
}

output "karpenter_node_role_name" {
  value = module.cluster.karpenter_node_role_name
}

output "karpenter_queue_name" {
  value = module.cluster.karpenter_queue_name
}
