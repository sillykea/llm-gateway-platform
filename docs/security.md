# Security controls

| Threat | Control | Where |
|---|---|---|
| Leaked CI credentials | No AWS keys; OIDC roles; apply only from approved environments | `bootstrap/`, ADR 0003 |
| Insecure change merged | Checkov, OPA guardrails on the plan, required review on prod | `ci.yml`, `plan.yml`, `policy/` |
| Kubernetes API exposed | Private endpoint; public only for listed /32s; OPA denies 0.0.0.0/0 | `modules/cluster` |
| Pod steals node credentials | IMDSv2 required, hop limit 1 | `modules/cluster` |
| Over-privileged workloads | Pod Identity role per component, scoped to one service account | `modules/cluster`, `modules/secrets` |
| Secrets in code or state | Terraform creates the secret, never the value | `modules/secrets` |
| Secrets readable in etcd | EKS envelope encryption with KMS | `modules/cluster` |
| Lateral movement in the cluster | Default-deny NetworkPolicies, enforced by the VPC CNI | chart, `modules/cluster` |
| Container breakout | Non-root, read-only root FS, all capabilities dropped, seccomp | chart |
| Data at rest | KMS on state, secrets, logs, EBS; ElastiCache encrypted with a customer-managed KMS key | everywhere |
| Data in transit | TLS on S3 (enforced by policy), ALB TLS 1.2+, Redis TLS with an auth token (ADR 0004) | Pod-to-pod traffic inside the cluster is unencrypted (no service mesh) |
| Undetected compromise | CloudTrail (validated), Config, GuardDuty incl. EKS runtime, Security Hub CIS | `modules/security-baseline` |
| Tampered audit logs | Log file validation, versioned KMS-encrypted bucket | `modules/security-baseline` |
| Stale dependencies | Renovate on providers, modules and charts | `renovate.json` |
