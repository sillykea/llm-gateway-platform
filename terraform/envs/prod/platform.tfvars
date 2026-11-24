state_bucket    = "llm-gateway-tfstate-<your-account-id>"
infra_state_key = "prod/infra.tfstate"
gitops_revision = "main"  # pin to a release tag (e.g. "v1.2.0") for controlled prod rollouts
