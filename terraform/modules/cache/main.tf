locals {
  ha = var.replicas > 0
}

resource "aws_elasticache_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "this" {
  name        = "${var.name}-cache"
  description = "Redis for the LLM gateway response cache"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "from_nodes" {
  for_each = toset(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.this.id
  description                  = "Redis from EKS nodes"
  referenced_security_group_id = each.value
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = var.name
  description          = "LLM gateway response cache"

  engine               = "redis"
  engine_version       = "7.1"
  parameter_group_name = "default.redis7"
  node_type            = var.node_type
  port                 = 6379

  num_cache_clusters         = 1 + var.replicas
  automatic_failover_enabled = local.ha
  multi_az_enabled           = local.ha

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.this.id]

  at_rest_encryption_enabled = true

  # The gateway's Redis client speaks plain RESP, not TLS. The cache sits in
  # isolated subnets and only the node security group can reach it, and it
  # holds cached model answers, never credentials. Trade-off recorded in
  # docs/adr/0004; adding TLS to the client is on the roadmap.
  transit_encryption_enabled = false

  snapshot_retention_limit   = var.snapshot_retention_days
  auto_minor_version_upgrade = true
  maintenance_window         = "sun:14:00-sun:15:00" # ~2-3am NZ time
  apply_immediately          = !local.ha
}
