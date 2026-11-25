data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = var.infra_state_key
    region = var.state_region
  }
}

locals {
  infra = data.terraform_remote_state.infra.outputs
}

# Terraform installs exactly one thing on the cluster: Argo CD and the root
# Application. Everything after that is reconciled from git (docs/adr/0002).
resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  values = [yamlencode({
    global = {
      domain = "argocd.local"
    }
    configs = {
      params = {
        # TLS terminates at the port-forward/ingress in front of the server.
        "server.insecure" = true
      }
      cm = {
        # Show and diff Argo CD resources by their real apps, not the root.
        "application.resourceTrackingMethod" = "annotation"
      }
    }
    dex = {
      enabled = false
    }
    server = {
      service = {
        type = "ClusterIP"
      }
    }
  })]
}

resource "helm_release" "root_app" {
  name      = "root"
  namespace = "argocd"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = var.argocd_apps_chart_version

  values = [yamlencode({
    applications = {
      root = {
        namespace = "argocd"
        project   = "default"
        finalizers = [
          "resources-finalizer.argocd.argoproj.io",
        ]
        source = {
          repoURL        = var.gitops_repo_url
          targetRevision = var.gitops_revision
          path           = "gitops/apps"
          helm = {
            # Environment facts flow from Terraform into git-managed apps
            # through these values, never through hand-edited files.
            valuesObject = {
              environment    = local.infra.environment
              repoURL        = var.gitops_repo_url
              targetRevision = var.gitops_revision
              aws = {
                region      = local.infra.region
                clusterName = local.infra.cluster_name
                vpcId       = local.infra.vpc_id
              }
              gateway = {
                redisAddress    = local.infra.redis_address
                secretName      = local.infra.secret_name
                redisSecretName = local.infra.redis_secret_name
              }
              console = {
                sessionSecretName = local.infra.console_session_secret_name
                syncSecretName    = local.infra.console_sync_secret_name
                usersSecretName   = local.infra.console_users_secret_name
              }
            }
          }
        }
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = "argocd"
        }
        syncPolicy = {
          automated = {
            prune    = true
            selfHeal = true
          }
        }
      }
    }
  })]

  depends_on = [helm_release.argocd]
}
