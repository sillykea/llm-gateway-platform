terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }

  # Partial config: bucket and key come from envs/<env>/infra.backend.hcl.
  backend "s3" {
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "llm-gateway-platform"
      Environment = var.environment
      ManagedBy   = "terraform"
      Stack       = "infra"
      Repository  = "github.com/sillykea/llm-gateway-platform"
    }
  }
}
