environment = "prod"
region      = "ap-southeast-2"
vpc_cidr    = "10.20.0.0/16"

# Resilience over cost: NAT per AZ, on-demand nodes across 3 AZs, cache failover.
single_nat_gateway  = false
node_instance_types = ["m6i.large", "m5.large"]
node_capacity_type  = "ON_DEMAND"
node_min_size       = 3
node_max_size       = 9
node_desired_size   = 3

cache_node_type = "cache.t4g.small"
cache_replicas  = 1

# admin_role_arns = ["arn:aws:iam::<account>:role/<your-admin-role>"]
