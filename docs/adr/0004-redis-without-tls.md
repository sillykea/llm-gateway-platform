# 4. ElastiCache without in-transit encryption (for now)

Status: accepted, revisit when the gateway's client supports TLS

## Context

The gateway's Redis client speaks plain RESP (the gateway uses only the Go
standard library; see the gateway repo's ADR 1). ElastiCache auth tokens
require in-transit encryption.

## Decision

Run Redis with at-rest encryption and without TLS or auth, and compensate:

- isolated subnets with no internet route
- a security group that admits only the EKS node security group on 6379
- a Kubernetes NetworkPolicy so only gateway pods egress to 6379
- the cache holds cached model answers, never credentials

## Consequences

Checkov checks CKV_AWS_191 and CKV_AWS_31 are skipped, with the reason in
`.checkov.yaml`. Closing the gap means adding `crypto/tls` to the gateway's
Redis client (a small change) and flipping `transit_encryption_enabled`,
which replaces the replication group, so the cache starts cold.
