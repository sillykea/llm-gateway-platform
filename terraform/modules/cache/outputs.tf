output "address" {
  description = "host:port for the gateway's cache.redis_addr."
  value       = "${aws_elasticache_replication_group.this.primary_endpoint_address}:6379"
}

output "security_group_id" {
  value = aws_security_group.this.id
}
