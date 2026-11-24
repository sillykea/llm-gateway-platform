data "aws_caller_identity" "current" {}

locals {
  name = "llm-gateway-${var.environment}"

  # The CI apply role for this environment (created by terraform/bootstrap)
  # always gets cluster-admin, so the platform stack can install Argo CD on
  # the first automated run. Extra roles (e.g. your own) come from tfvars.
  ci_apply_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-terraform-apply-${var.environment}"
}

module "network" {
  source = "../../modules/network"

  name               = local.name
  cidr               = var.vpc_cidr
  single_nat_gateway = var.single_nat_gateway
  cluster_name       = local.name
}

module "cluster" {
  source = "../../modules/cluster"

  cluster_name             = local.name
  kubernetes_version       = var.kubernetes_version
  vpc_id                   = module.network.vpc_id
  private_subnet_ids       = module.network.private_subnet_ids
  control_plane_subnet_ids = module.network.intra_subnet_ids
  public_endpoint_cidrs    = var.public_endpoint_cidrs
  admin_role_arns          = distinct(concat([local.ci_apply_role_arn], var.admin_role_arns))

  node_instance_types = var.node_instance_types
  node_capacity_type  = var.node_capacity_type
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  node_desired_size   = var.node_desired_size
}

module "cache" {
  source = "../../modules/cache"

  name                       = local.name
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.intra_subnet_ids
  allowed_security_group_ids = [module.cluster.node_security_group_id]
  node_type                  = var.cache_node_type
  replicas                   = var.cache_replicas
  kms_key_arn                = module.secrets.kms_key_arn
}

module "secrets" {
  source = "../../modules/secrets"

  name                   = "llm-gateway/${var.environment}"
  cluster_name           = module.cluster.cluster_name
  additional_secret_arns = [module.cache.auth_secret_arn]
}
