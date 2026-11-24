# Account-wide security controls, applied once per AWS account.
module "security_baseline" {
  source = "../../modules/security-baseline"

  name                                = "llm-gateway"
  enable_guardduty_runtime_monitoring = var.enable_guardduty_runtime_monitoring
}

output "audit_bucket" {
  value = module.security_baseline.audit_bucket
}
