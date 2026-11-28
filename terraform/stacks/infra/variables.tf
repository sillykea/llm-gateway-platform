variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "vpc_cidr" {
  type = string
}

variable "single_nat_gateway" {
  type = bool
}

variable "kubernetes_version" {
  type    = string
  default = "1.31"
}

variable "public_endpoint_cidrs" {
  description = "Your IP as x.x.x.x/32 to run kubectl from home. Empty keeps the API private."
  type        = list(string)
  default     = []
}

variable "admin_role_arns" {
  description = "Extra IAM roles that get cluster-admin, e.g. your own admin role. The CI apply role is always included."
  type        = list(string)
  default     = []
}

variable "node_instance_types" {
  type = list(string)
}

variable "node_capacity_type" {
  type = string
}

variable "node_min_size" {
  type = number
}

variable "node_max_size" {
  type = number
}

variable "node_desired_size" {
  type = number
}

variable "cache_node_type" {
  type = string
}

variable "cache_replicas" {
  type = number
}

variable "enable_gpu_inference" {
  description = "Run self-hosted models on GPU nodes: installs Karpenter's AWS side here, and KEDA, Karpenter and llm-operator through Argo CD."
  type        = bool
  default     = false
}
