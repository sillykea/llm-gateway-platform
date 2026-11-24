variable "name" {
  description = "Secret name, e.g. llm-gateway/dev."
  type        = string
}

variable "cluster_name" {
  type = string
}

variable "namespace" {
  description = "Namespace of the External Secrets Operator controller."
  type        = string
  default     = "external-secrets"
}

variable "service_account" {
  description = "Service account of the External Secrets Operator controller."
  type        = string
  default     = "external-secrets"
}

variable "additional_secret_arns" {
  description = "Other secrets (encrypted with this module's key) the reader may access, e.g. the Redis auth token."
  type        = list(string)
  default     = []
}
