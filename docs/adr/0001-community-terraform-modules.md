# 1. Use community Terraform modules for VPC and EKS

Status: accepted

## Context

A production-grade VPC and EKS cluster is several hundred resources' worth of
edge cases: route tables per AZ, flow log IAM, add-on ordering, access
entries, launch templates.

## Decision

Wrap `terraform-aws-modules/vpc` and `terraform-aws-modules/eks` in thin
local modules (`modules/network`, `modules/cluster`) that expose only the
choices this platform makes. Pin to a minor version range.

## Consequences

- Widely used, well-tested code for the undifferentiated parts.
- The local wrappers are the interface the stacks depend on, so swapping a
  community module, or forking it, touches one directory.
- Major upgrades of the community modules (e.g. EKS module v20 → v21 renamed
  many inputs) are deliberate work, not a Renovate auto-merge.
