terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }

  # Bootstrap creates the state bucket, so its own state starts local.
  # After the first apply, migrate it with: terraform init -migrate-state
  # using backend.tf.example.
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "llm-gateway-platform"
      ManagedBy = "terraform"
      Stack     = "bootstrap"
    }
  }
}
