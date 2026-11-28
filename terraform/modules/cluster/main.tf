module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  control_plane_subnet_ids = var.control_plane_subnet_ids

  # Private endpoint always on. The public endpoint is only opened to the
  # CIDRs given, and turned off entirely when none are.
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = length(var.public_endpoint_cidrs) > 0
  cluster_endpoint_public_access_cidrs = var.public_endpoint_cidrs

  # Kubernetes Secrets are envelope-encrypted with a KMS key the module creates.
  cluster_encryption_config = {
    resources = ["secrets"]
  }

  cluster_enabled_log_types              = ["api", "audit", "authenticator"]
  cloudwatch_log_group_retention_in_days = var.log_retention_days

  # Access is granted through EKS access entries, not the aws-auth ConfigMap.
  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = false

  access_entries = {
    for i, arn in var.admin_role_arns : "admin-${i}" => {
      principal_arn = arn
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  cluster_addons = {
    coredns                = { most_recent = true }
    kube-proxy             = { most_recent = true }
    eks-pod-identity-agent = { most_recent = true }
    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          # Pack more pods per node by giving out IP prefixes, not single IPs.
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
        # Enforce Kubernetes NetworkPolicy objects (the chart ships some).
        enableNetworkPolicy = "true"
      })
    }
    aws-ebs-csi-driver = {
      most_recent = true
      pod_identity_association = [{
        role_arn        = module.ebs_csi_pod_identity.iam_role_arn
        service_account = "ebs-csi-controller-sa"
      }]
    }
  }

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      # Roll nodes one at a time so the gateway's PodDisruptionBudget holds.
      update_config = {
        max_unavailable = 1
      }

      # IMDSv2 only, and pods can't reach the node's instance role through it.
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
      }

      block_device_mappings = {
        root = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      labels = {
        workload = "general"
      }
    }
  }
}

# Pod Identity roles for cluster add-ons. Each is scoped to one service
# account, so a compromised pod can't use another component's permissions.
module "ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.7"

  name                      = "${var.cluster_name}-ebs-csi"
  attach_aws_ebs_csi_policy = true
}

module "lb_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.7"

  name                            = "${var.cluster_name}-aws-lb-controller"
  attach_aws_lb_controller_policy = true

  associations = {
    controller = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }
}

# Karpenter launches GPU nodes for the inference pool on demand and removes
# them when the pool scales to zero (docs/adr/0008). The module creates the
# controller's Pod Identity role, the role GPU nodes run as, their EKS access
# entry, and an SQS queue for spot interruption and rebalance notices.
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.31"
  count   = var.enable_karpenter ? 1 : 0

  cluster_name          = module.eks.cluster_name
  enable_v1_permissions = true

  enable_pod_identity             = true
  create_pod_identity_association = true
  namespace                       = "kube-system"
  service_account                 = "karpenter"

  # A fixed name, so the EC2NodeClass in git can refer to it.
  node_iam_role_use_name_prefix = false
  node_iam_role_name            = "${var.cluster_name}-karpenter-node"
  node_iam_role_additional_policies = {
    # Session Manager instead of SSH for debugging a GPU node.
    ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}
