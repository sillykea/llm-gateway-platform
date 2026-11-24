# 3. CI access: OIDC roles with narrow trust, broad permissions on apply

Status: accepted

## Context

CI needs AWS access. Long-lived access keys in GitHub secrets can leak and
never expire.

## Decision

- GitHub Actions assumes AWS roles with OIDC. No AWS keys exist anywhere.
- **Plan role:** `ReadOnlyAccess` plus state bucket access. Assumable from
  pull requests and `main`.
- **Apply roles:** one per environment, assumable *only* by jobs running in
  the matching GitHub environment (`sub = repo:…:environment:prod`). The prod
  environment requires a reviewer.
- Apply roles use `AdministratorAccess`.

## Consequences

The control is on *who and when* rather than *what*: a stolen PR token can't
apply anything, and nothing reaches prod without an approval. A scoped apply
policy is better and is on the roadmap. It's deferred because EKS, IAM and
KMS creation need wide permissions, and a too-narrow policy fails half way
through an apply, which is a worse failure mode for a small team. The OPA
guardrail denying hand-written `*:*` policies keeps this exception from
spreading.
