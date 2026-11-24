locals {
  name = "llm-gateway-${var.environment}"
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
  admin_role_arns          = var.admin_role_arns

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
}

module "secrets" {
  source = "../../modules/secrets"

  name         = "llm-gateway/${var.environment}"
  cluster_name = module.cluster.cluster_name
}
