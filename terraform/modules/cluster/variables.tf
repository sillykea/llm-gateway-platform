variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version. Upgrade one minor version at a time (see docs/runbook.md)."
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  description = "Subnets for worker nodes."
  type        = list(string)
}

variable "control_plane_subnet_ids" {
  description = "Subnets for the control plane's network interfaces."
  type        = list(string)
}

variable "public_endpoint_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint. Empty list makes the endpoint private only."
  type        = list(string)
  default     = []
}

variable "node_instance_types" {
  description = "Instance types for the default node group, in order of preference."
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT. Spot is fine for dev; prod defaults to on-demand."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 5
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "admin_role_arns" {
  description = "IAM roles granted cluster-admin through EKS access entries."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  type    = number
  default = 30
}
