# 6. Prevent, then detect

Status: accepted

## Decision

Security controls sit at three points:

1. **Before merge (preventive):** Checkov on the Terraform and rendered
   manifests; OPA guardrails on the actual plan; kubeconform on schemas.
2. **At runtime (preventive):** private API endpoint by default, IMDSv2 with
   hop limit 1, KMS everywhere, NetworkPolicies, non-root read-only containers,
   per-component Pod Identity roles, secrets that never touch Terraform state.
3. **After the fact (detective):** CloudTrail with log validation, AWS Config,
   GuardDuty with EKS audit-log and runtime monitoring, Security Hub against the
   CIS benchmark and AWS foundational best practices.

## Consequences

Preventive checks are cheap and fast but only catch what was anticipated.
Detective controls catch the rest, at a running cost of a few dollars a
month for a small account. docs/security.md maps each control to the threat
it addresses.
