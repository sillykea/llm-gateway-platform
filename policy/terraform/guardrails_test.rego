package main

import rego.v1

plan(cs) := {"resource_changes": cs, "variables": {"environment": {"value": "dev"}}}

prod_plan(cs) := {"resource_changes": cs, "variables": {"environment": {"value": "prod"}}}

rc(type, after, actions) := {
	"address": sprintf("%s.test", [type]),
	"type": type,
	"change": {"actions": actions, "after": after},
}

test_ssh_open_to_world_denied if {
	count(deny) == 1 with input as plan([rc("aws_vpc_security_group_ingress_rule", {"cidr_ipv4": "0.0.0.0/0", "from_port": 22}, ["create"])])
}

test_https_open_to_world_allowed if {
	count(deny) == 0 with input as plan([rc("aws_vpc_security_group_ingress_rule", {"cidr_ipv4": "0.0.0.0/0", "from_port": 443}, ["create"])])
}

test_redis_from_node_sg_allowed if {
	count(deny) == 0 with input as plan([rc("aws_vpc_security_group_ingress_rule", {"referenced_security_group_id": "sg-1", "from_port": 6379}, ["create"])])
}

test_public_eks_api_denied if {
	cluster := {"vpc_config": [{"endpoint_public_access": true, "public_access_cidrs": ["0.0.0.0/0"]}]}
	count(deny) == 1 with input as plan([rc("aws_eks_cluster", cluster, ["create"])])
}

test_eks_api_limited_to_home_ip_allowed if {
	cluster := {"vpc_config": [{"endpoint_public_access": true, "public_access_cidrs": ["203.0.113.10/32"]}]}
	count(deny) == 0 with input as plan([rc("aws_eks_cluster", cluster, ["create"])])
}

test_unencrypted_cache_denied if {
	count(deny) == 1 with input as plan([rc("aws_elasticache_replication_group", {"at_rest_encryption_enabled": false}, ["create"])])
}

test_star_star_policy_denied if {
	doc := json.marshal({"Statement": [{"Effect": "Allow", "Action": "*", "Resource": "*"}]})
	count(deny) == 1 with input as plan([rc("aws_iam_policy", {"policy": doc}, ["create"])])
}

test_scoped_policy_allowed if {
	doc := json.marshal({"Statement": [{"Effect": "Allow", "Action": ["s3:GetObject"], "Resource": "arn:aws:s3:::b/*"}]})
	count(deny) == 0 with input as plan([rc("aws_iam_policy", {"policy": doc}, ["create"])])
}

test_destroying_cache_warns_in_dev if {
	cs := [rc("aws_elasticache_replication_group", null, ["delete"])]
	count(deny) == 0 with input as plan(cs)
	count(warn) == 1 with input as plan(cs)
}

test_destroying_cache_denied_in_prod if {
	count(deny) == 1 with input as prod_plan([rc("aws_elasticache_replication_group", null, ["delete"])])
}

test_replacing_cluster_denied_in_prod if {
	count(deny) == 1 with input as prod_plan([rc("aws_eks_cluster", {"vpc_config": []}, ["delete", "create"])])
}
