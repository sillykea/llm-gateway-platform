locals {
  ha = var.replicas > 0
}

# ElastiCache auth tokens allow printable characters except @ " / and
# spaces; alphanumeric keeps it simple and still 190+ bits of entropy.
resource "random_password" "auth" {
  length  = 32
  special = false
}

# The token is handed to the gateway through Secrets Manager and External
# Secrets, the same path as the API keys. It is also in Terraform state,
# which is KMS-encrypted and readable only by the CI roles (docs/adr/0004).
resource "aws_secretsmanager_secret" "auth" {
  name                    = "${replace(var.name, "llm-gateway-", "llm-gateway/")}/redis"
  description             = "ElastiCache auth token for the gateway cache"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "auth" {
  secret_id     = aws_secretsmanager_secret.auth.id
  secret_string = jsonencode({ REDIS_PASSWORD = random_password.auth.result })
}

resource "aws_elasticache_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.subnet_ids
}

# Our own parameter group, so settings can be tuned later without replacing
# the cluster (the AWS default groups are read-only).
resource "aws_elasticache_parameter_group" "this" {
  name   = var.name
  family = "redis7"

  # It's a cache: evict the least recently used keys when memory is full,
  # rather than rejecting writes.
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
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
  parameter_group_name = aws_elasticache_parameter_group.this.name
  node_type            = var.node_type
  port                 = 6379

  num_cache_clusters         = 1 + var.replicas
  automatic_failover_enabled = local.ha
  multi_az_enabled           = local.ha

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.this.id]

  # Encrypted at rest and in transit, and every connection must AUTH.
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.auth.result

  snapshot_retention_limit   = var.snapshot_retention_days
  auto_minor_version_upgrade = true
  maintenance_window         = "sun:14:00-sun:15:00" # ~2-3am NZ time
  apply_immediately          = !local.ha
}
