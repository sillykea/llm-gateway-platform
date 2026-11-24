variable "name" {
  description = "Name prefix, e.g. llm-gateway-dev."
  type        = string
}

variable "cidr" {
  description = "VPC CIDR block. Each environment gets its own range so they could be peered later."
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr, 0)) && tonumber(split("/", var.cidr)[1]) <= 20
    error_message = "cidr must be a valid IPv4 block of /20 or larger, to leave room for three AZs of each subnet tier."
  }
}

variable "az_count" {
  description = "Number of availability zones to spread across."
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3. EKS needs at least two zones."
  }
}

variable "single_nat_gateway" {
  description = "One shared NAT gateway (cheap, one zone can take egress down) or one per AZ (resilient). See docs/adr/0005."
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "EKS cluster name, used to tag subnets for load balancer discovery."
  type        = string
}

variable "flow_log_retention_days" {
  description = "How long to keep VPC flow logs."
  type        = number
  default     = 30
}
