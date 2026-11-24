variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "enable_guardduty_runtime_monitoring" {
  type    = bool
  default = true
}

variable "create_config_service_linked_role" {
  description = "Set false if AWS Config's service-linked role already exists."
  type        = bool
  default     = true
}
