# Usage: make <target> ENV=dev|prod
ENV    ?= dev
REGION ?= ap-southeast-2
TF      = terraform -chdir=terraform/stacks

.PHONY: help bootstrap account infra platform kubeconfig secrets argocd destroy lint render policy-test local-up local-down

help:
	@grep -E '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) | awk -F':.*?## ' '{printf "  %-12s %s\n", $$1, $$2}'

bootstrap: ## One-time: state bucket and GitHub OIDC roles
	terraform -chdir=terraform/bootstrap init
	terraform -chdir=terraform/bootstrap apply

account: ## Account security baseline (GuardDuty, Security Hub, CloudTrail, Config)
	$(TF)/account init -backend-config=../../envs/account/account.backend.hcl
	$(TF)/account apply

infra: ## Network, EKS, Redis and secrets for ENV
	$(TF)/infra init -reconfigure -backend-config=../../envs/$(ENV)/infra.backend.hcl
	$(TF)/infra apply -var-file=../../envs/$(ENV)/infra.tfvars

platform: ## Install Argo CD and hand the cluster over to GitOps
	$(TF)/platform init -reconfigure -backend-config=../../envs/$(ENV)/platform.backend.hcl
	$(TF)/platform apply -var-file=../../envs/$(ENV)/platform.tfvars

kubeconfig: ## Point kubectl at the ENV cluster
	aws eks update-kubeconfig --region $(REGION) --name llm-gateway-$(ENV)

secrets: ## Store API keys in Secrets Manager (prompts; never written to disk)
	@read -s -p "Gateway API key: " gw; echo; read -s -p "OpenAI API key (blank for local-only): " oa; echo; \
	aws secretsmanager put-secret-value --region $(REGION) --secret-id llm-gateway/$(ENV) \
	  --secret-string "$$(printf '{"GATEWAY_API_KEY":"%s","OPENAI_API_KEY":"%s"}' "$$gw" "$$oa")" >/dev/null && echo stored

console-users: ## Store console sign-ins (users.json) in Secrets Manager
	@test -f "$(USERS)" || { echo "usage: make console-users ENV=dev USERS=path/to/users.json"; exit 1; }
	aws secretsmanager put-secret-value --region $(REGION) --secret-id llm-gateway/$(ENV)/console-users \
	  --secret-string "$$(python3 -c 'import json,sys; print(json.dumps({"users.json": open(sys.argv[1]).read()}))' "$(USERS)")" >/dev/null && echo stored

console: ## Open the console on http://localhost:8090
	kubectl -n llm-gateway-console port-forward svc/llm-gateway-console 8090:80

argocd: ## Open the Argo CD UI on http://localhost:8080
	@echo "password: $$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
	kubectl -n argocd port-forward svc/argocd-server 8080:80

destroy: ## Tear down ENV (platform first, then infra)
	$(TF)/platform init -reconfigure -backend-config=../../envs/$(ENV)/platform.backend.hcl
	$(TF)/platform destroy -var-file=../../envs/$(ENV)/platform.tfvars
	$(TF)/infra init -reconfigure -backend-config=../../envs/$(ENV)/infra.backend.hcl
	$(TF)/infra destroy -var-file=../../envs/$(ENV)/infra.tfvars

lint: ## Format check, validate, tflint and Checkov
	terraform fmt -check -recursive terraform
	for d in bootstrap stacks/account stacks/infra stacks/platform; do terraform -chdir=terraform/$$d init -backend=false -input=false >/dev/null && terraform -chdir=terraform/$$d validate; done
	tflint --init && tflint --recursive --chdir terraform
	checkov --config-file .checkov.yaml -d terraform --framework terraform

render: ## Render the chart for ENV to stdout
	helm template llm-gateway charts/llm-gateway -n llm-gateway -f charts/llm-gateway/values-$(ENV).yaml \
	  --set image.tag=local --set externalSecret.remoteKey=llm-gateway/$(ENV) --set redisAddress=redis:6379

policy-test: ## Unit-test the OPA guardrails
	conftest verify --policy policy/terraform

local-up: ## Run the gateway chart on a local kind cluster (no AWS needed)
	bash local/up.sh

local-down: ## Delete the local kind cluster
	kind delete cluster --name llm-gateway
