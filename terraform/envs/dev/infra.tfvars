environment = "dev"
region      = "ap-southeast-2"
vpc_cidr    = "10.10.0.0/16"

# Cost over resilience: one NAT gateway, spot nodes, no cache replica.
single_nat_gateway  = true
node_instance_types = ["t3.large", "t3a.large", "m5.large"]
node_capacity_type  = "SPOT"
node_min_size       = 1
node_max_size       = 3
node_desired_size   = 2

cache_node_type = "cache.t4g.micro"
cache_replicas  = 0

# public_endpoint_cidrs = ["203.0.113.10/32"]  # your IP, to use kubectl from home
# admin_role_arns       = ["arn:aws:iam::<account>:role/<your-admin-role>"]

# GPU inference: Karpenter, KEDA and llm-operator (docs/adr/0008). Off until
# you want to pay for GPU nodes; with the pool at zero, they cost nothing.
enable_gpu_inference = false
