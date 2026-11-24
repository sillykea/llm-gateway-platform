# Account-wide security controls, applied once per AWS account.
module "security_baseline" {
  source = "../../modules/security-baseline"

  name                                = "llm-gateway"
  enable_guardduty_runtime_monitoring = var.enable_guardduty_runtime_monitoring
  create_config_service_linked_role   = var.create_config_service_linked_role
}

output "audit_bucket" {
  value = module.security_baseline.audit_bucket
}
