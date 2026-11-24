# 4. Redis with TLS and an auth token

Status: accepted (supersedes "Redis without TLS")

## Context

The gateway's Redis client originally spoke plain RESP, so ElastiCache ran
without in-transit encryption or auth, compensated by network isolation. That
left two Checkov exceptions and an honest gap in the threat model.

## Decision

- The gateway's client gained TLS (`crypto/tls`, verifying the server
  certificate against the system roots, which trust ElastiCache's) and AUTH.
- ElastiCache runs with `transit_encryption_enabled` and an `auth_token`.
- Terraform generates the token (`random_password`) and stores it in its own
  Secrets Manager secret, encrypted with the environment's KMS key. External
  Secrets merges it into the gateway's Secret as `REDIS_PASSWORD`, the same
  path the API keys take.
- Network isolation stays: isolated subnets, node-only security group,
  NetworkPolicy. Encryption and auth are layered on top, not instead.

## Consequences

- The Checkov exceptions for ElastiCache in-transit encryption and auth are gone.
- The token exists in Terraform state. State is KMS-encrypted, versioned, and
  readable only by the CI roles and account admins; that is accepted. Moving
  to ElastiCache RBAC users with IAM authentication would remove it from state
  and is the next step if the threat model requires it.
- Rotating the token: taint `random_password.auth` and apply. ElastiCache
  accepts the new token, External Secrets syncs it within the refresh
  interval, and a rollout restart picks it up.
- Local development (kind) keeps plain Redis via `local/values-local.yaml`.
