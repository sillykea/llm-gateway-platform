output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group of the worker nodes; ElastiCache allows inbound from it."
  value       = module.eks.node_security_group_id
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "karpenter_node_role_name" {
  description = "IAM role GPU nodes launched by Karpenter run as; empty when Karpenter is off."
  value       = var.enable_karpenter ? module.karpenter[0].node_iam_role_name : ""
}

output "karpenter_queue_name" {
  description = "SQS queue for spot interruption notices; empty when Karpenter is off."
  value       = var.enable_karpenter ? module.karpenter[0].queue_name : ""
}
