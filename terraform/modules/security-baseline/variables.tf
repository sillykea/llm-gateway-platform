variable "name" {
  description = "Prefix for resources, e.g. llm-gateway."
  type        = string
}

variable "log_retention_days" {
  description = "Days to keep CloudTrail and Config history in S3 before expiry."
  type        = number
  default     = 365
}

variable "enable_guardduty_runtime_monitoring" {
  description = "GuardDuty agent on EKS nodes. Catches crypto-miners and shells in pods; costs extra per vCPU."
  type        = bool
  default     = true
}

variable "create_config_service_linked_role" {
  description = "Set false if AWS Config's service-linked role already exists in the account."
  type        = bool
  default     = true
}
