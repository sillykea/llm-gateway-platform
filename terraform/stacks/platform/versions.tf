terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }

  backend "s3" {
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = local.infra.region

  default_tags {
    tags = {
      Project     = "llm-gateway-platform"
      Environment = local.infra.environment
      ManagedBy   = "terraform"
      Stack       = "platform"
    }
  }
}

# The cluster lives in a separate stack, so this provider is configured from
# values that already exist at plan time. Keeping the cluster and the things
# installed on it in one stack breaks plans whenever the cluster is replaced.
provider "helm" {
  kubernetes {
    host                   = local.infra.cluster_endpoint
    cluster_ca_certificate = base64decode(local.infra.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.infra.cluster_name, "--region", local.infra.region]
    }
  }
}
