variable "state_bucket" {
  description = "Bucket holding the infra stack's state."
  type        = string
}

variable "infra_state_key" {
  description = "State key of this environment's infra stack, e.g. dev/infra.tfstate."
  type        = string
}

variable "state_region" {
  type    = string
  default = "ap-southeast-2"
}

variable "gitops_repo_url" {
  type    = string
  default = "https://github.com/sillykea/llm-gateway-platform.git"
}

variable "gitops_revision" {
  description = "Branch or tag Argo CD follows. Prod can pin a release tag."
  type        = string
  default     = "main"
}

variable "argocd_chart_version" {
  type = string
  # renovate: datasource=helm depName=argo-cd registryUrl=https://argoproj.github.io/argo-helm
  default = "7.7.0"
}

variable "argocd_apps_chart_version" {
  type = string
  # renovate: datasource=helm depName=argocd-apps registryUrl=https://argoproj.github.io/argo-helm
  default = "2.0.2"
}
