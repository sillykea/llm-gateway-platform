variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "enable_guardduty_runtime_monitoring" {
  type    = bool
  default = true
}
