variable "region" {
  description = "AWS region for the state bucket and shared resources."
  type        = string
  default     = "ap-southeast-2"
}

variable "github_repository" {
  description = "GitHub repository (owner/name) allowed to assume the CI roles."
  type        = string
  default     = "sillykea/llm-gateway-platform"
}

variable "state_bucket_name" {
  description = "Globally unique name for the Terraform state bucket."
  type        = string
}

variable "environments" {
  description = "Deployment environments. Each gets an apply role trusted only for its GitHub environment."
  type        = set(string)
  default     = ["dev", "prod"]
}
