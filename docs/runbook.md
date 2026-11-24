# Runbook

## First-time setup

Prerequisites: an AWS account, admin credentials on your machine, Terraform
≥ 1.10, `aws`, `kubectl`, `helm`.

```bash
# 1. State bucket and CI roles (local state for this one stack)
cp terraform/bootstrap/terraform.tfvars.example terraform/bootstrap/terraform.tfvars   # set bucket name
make bootstrap

# 2. Replace <your-account-id> in terraform/envs/**/*.hcl and *.tfvars, then:
make account
make infra ENV=dev        # ~15 minutes
make secrets ENV=dev      # prompts for keys, stores them in Secrets Manager
make platform ENV=dev     # Argo CD takes over from here
make kubeconfig ENV=dev && make argocd
```

Connect CI. In the repository settings:

- **Variables:** `AWS_PLAN_ROLE_ARN` (bootstrap output `plan_role_arn`)
- **Environments:** create `dev` and `prod`, each with the variable
  `AWS_APPLY_ROLE_ARN` (from `apply_role_arns`). On `prod`, add required
  reviewers.
- **Secrets (optional):** `INFRACOST_API_KEY` for cost comments on PRs.
- Add each apply role to `admin_role_arns` in the env's `infra.tfvars`, so the
  platform stack can install Argo CD.

The gateway image on GHCR must be public, or the cluster needs a pull secret:
GitHub → Packages → llm-gateway → Package settings → Change visibility.

## Deploy a new gateway version

1. The gateway repo's CI pushes `ghcr.io/sillykea/llm-gateway:<sha>`.
2. Change `gateway.imageTag` in `gitops/apps/values.yaml` and open a PR.
3. After merge, Argo CD rolls it out. The rolling update has `maxUnavailable: 0`,
   and the readiness probe gates traffic, so no requests are dropped.

## Roll back

- **App:** `git revert` the commit, merge. Argo CD syncs the previous state.
  In an emergency, use *History and rollback* in the Argo CD UI, then revert
  in git so self-heal doesn't undo the rollback.
- **Infrastructure:** revert the Terraform change and let `apply` run. Check
  the plan comment first; some changes (e.g. Redis TLS) replace resources.

## Rotate the API keys

```bash
make secrets ENV=prod
```

External Secrets picks up the new value within `refreshInterval` (1 hour).
To apply it immediately:

```bash
kubectl -n llm-gateway annotate externalsecret llm-gateway force-sync=$(date +%s) --overwrite
kubectl -n llm-gateway rollout restart deploy/llm-gateway
```

## Upgrade Kubernetes

EKS upgrades one minor version at a time.

1. Read the EKS release notes for removed APIs. Check the rendered manifests:
   `make render ENV=prod | kubeconform -kubernetes-version <new>`.
2. Bump `kubernetes_version` in dev's tfvars, merge, and watch the dev apply
   (the control plane first, then nodes roll one at a time under the PDB).
3. Leave it a few days, then do the same for prod.

## Pods not ready

```bash
kubectl -n llm-gateway get pods,externalsecret
kubectl -n llm-gateway describe pod -l app.kubernetes.io/name=llm-gateway
```

| Symptom | Likely cause |
|---|---|
| `CreateContainerConfigError`, secret not found | ExternalSecret not synced: `kubectl describe externalsecret`; check the secret has a value (`make secrets`) |
| `ImagePullBackOff` | GHCR package is private, or the tag doesn't exist |
| Running but not ready | `/readyz` fails when Redis is unreachable: check the SG and NetworkPolicy |
| Pending | No capacity: check the node group in the console, and spot availability in dev |

## Disaster recovery

Everything is code or data that can be regenerated. The only state that
matters is Terraform state (versioned S3) and the API keys (Secrets Manager,
7-day recovery window).

Rebuild an environment from nothing:

```bash
make destroy ENV=dev
make infra ENV=dev && make secrets ENV=dev && make platform ENV=dev
```

Target: back to serving in under 30 minutes. The cache starts cold, and Ollama
re-downloads its models on first start.

## Tear down to stop paying

```bash
make destroy ENV=dev
```

The state bucket, KMS keys and the account baseline remain, costing a
few dollars a month at most. Their KMS keys have a 30-day deletion window.
