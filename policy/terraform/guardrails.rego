# Guardrails evaluated against `terraform show -json` plan output in CI.
# Checkov scans the code statically; these rules check the *plan*, so they
# also catch values that only exist once variables and modules resolve.
package main

import rego.v1

changes contains rc if {
	some rc in input.resource_changes
	some action in rc.change.actions
	action in {"create", "update"}
}

# 1. No security group may open anything but HTTP(S) to the whole internet.
deny contains msg if {
	some rc in changes
	rc.type == "aws_vpc_security_group_ingress_rule"
	after := rc.change.after
	after.cidr_ipv4 == "0.0.0.0/0"
	not after.from_port in {80, 443}
	msg := sprintf("%s opens port %v to 0.0.0.0/0; only 80/443 may be public", [rc.address, after.from_port])
}

deny contains msg if {
	some rc in changes
	rc.type == "aws_security_group"
	some rule in rc.change.after.ingress
	"0.0.0.0/0" in rule.cidr_blocks
	not rule.from_port in {80, 443}
	msg := sprintf("%s has an inline ingress rule open to 0.0.0.0/0 on port %v", [rc.address, rule.from_port])
}

# 2. The Kubernetes API is never open to the whole internet.
deny contains msg if {
	some rc in changes
	rc.type == "aws_eks_cluster"
	vpc := rc.change.after.vpc_config[_]
	vpc.endpoint_public_access == true
	"0.0.0.0/0" in vpc.public_access_cidrs
	msg := sprintf("%s exposes the Kubernetes API to 0.0.0.0/0; restrict public_endpoint_cidrs", [rc.address])
}

# 3. Data at rest is encrypted.
deny contains msg if {
	some rc in changes
	rc.type == "aws_elasticache_replication_group"
	not rc.change.after.at_rest_encryption_enabled
	msg := sprintf("%s must enable at-rest encryption", [rc.address])
}

deny contains msg if {
	some rc in changes
	rc.type == "aws_ebs_volume"
	not rc.change.after.encrypted
	msg := sprintf("%s must be encrypted", [rc.address])
}

# 4. No bucket is made public through an ACL.
deny contains msg if {
	some rc in changes
	rc.type == "aws_s3_bucket_acl"
	rc.change.after.acl in {"public-read", "public-read-write", "authenticated-read"}
	msg := sprintf("%s grants a public ACL", [rc.address])
}

# 5. No hand-written IAM policy grants every action on every resource.
#    (Admin access is only ever the AWS-managed policy, attached to the
#    environment-gated apply roles; see docs/adr/0003.)
deny contains msg if {
	some rc in changes
	rc.type in {"aws_iam_policy", "aws_iam_role_policy"}
	policy := json.unmarshal(rc.change.after.policy)
	some stmt in as_array(policy.Statement)
	stmt.Effect == "Allow"
	"*" in as_array(stmt.Action)
	"*" in as_array(stmt.Resource)
	msg := sprintf("%s allows Action * on Resource *", [rc.address])
}

# 6. Destroying stateful resources needs a human to look twice. In prod this
#    fails the plan; in dev it is a warning.
stateful := {
	"aws_elasticache_replication_group",
	"aws_secretsmanager_secret",
	"aws_kms_key",
	"aws_s3_bucket",
	"aws_eks_cluster",
}

destroys contains rc if {
	some rc in input.resource_changes
	rc.type in stateful
	"delete" in rc.change.actions
}

deny contains msg if {
	some rc in destroys
	is_prod
	msg := sprintf("%s would be destroyed in prod; apply manually with a reviewed plan", [rc.address])
}

warn contains msg if {
	some rc in destroys
	not is_prod
	msg := sprintf("%s will be destroyed", [rc.address])
}

is_prod if input.variables.environment.value == "prod"

as_array(x) := x if is_array(x)

as_array(x) := [x] if not is_array(x)
