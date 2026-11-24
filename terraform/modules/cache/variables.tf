variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "Isolated (intra) subnets. The cache has no route to the internet."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Only these security groups (the EKS nodes) may connect."
  type        = list(string)
}

variable "node_type" {
  type    = string
  default = "cache.t4g.micro"
}

variable "replicas" {
  description = "Read replicas in addition to the primary. 0 for dev, 1+ gives automatic failover."
  type        = number
  default     = 0
}

variable "snapshot_retention_days" {
  description = "Daily snapshots to keep. The cache holds no data we can't regenerate, so this is short."
  type        = number
  default     = 1
}

variable "kms_key_arn" {
  description = "Customer-managed KMS key for the cache data at rest and the auth token secret."
  type        = string
}
