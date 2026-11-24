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

output "kubeconfig_command" {
  description = "Run this to point kubectl at the cluster."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.cluster.cluster_name}"
}
