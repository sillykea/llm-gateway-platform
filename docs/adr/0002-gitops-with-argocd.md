# 2. Terraform builds the cluster; Argo CD runs what's on it

Status: accepted

## Context

Terraform can install Helm charts, but then every in-cluster change needs
cluster credentials in CI, drift isn't corrected until someone runs a plan,
and a stack that creates a cluster *and* configures its provider from that
cluster breaks whenever the cluster is replaced.

## Decision

- Terraform installs exactly one thing on the cluster: Argo CD and a root
  Application, from a separate `platform` stack.
- Everything else is an Argo CD Application rendered from `gitops/apps`.
- Facts only Terraform knows (cluster name, VPC ID, Redis address, secret
  name) are passed into the root Application as Helm values, never copied
  into files by hand.

## Consequences

- CI never holds Kubernetes credentials. Argo CD pulls from git.
- Manual `kubectl edit` changes are reverted automatically (`selfHeal`).
- Rolling back an app is `git revert`.
- Two delivery paths to understand (see architecture.md). The split is by
  ownership: AWS resources vs. workloads.
