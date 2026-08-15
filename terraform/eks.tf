module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.24"

  name               = local.cluster_name
  kubernetes_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  endpoint_public_access  = true
  endpoint_private_access = true

  enable_irsa = true
  node_security_group_additional_rules = {

  }

  enable_cluster_creator_admin_permissions = true
  access_entries = {
    github_actions = {
      principal_arn = "arn:aws:iam::814383264015:role/GitHubActionsCloudCommerceDeploy"

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

  addons = {
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }

    kube-proxy = {
      most_recent    = true
      before_compute = true
    }

    coredns = {
      most_recent = true
    }

    eks-pod-identity-agent = {
      most_recent = true
    }

    aws-ebs-csi-driver = {
      most_recent = true

      pod_identity_association = [{
        role_arn        = aws_iam_role.ebs_csi.arn
        service_account = "ebs-csi-controller-sa"
      }]
    }
    metrics-server = {
      most_recent = true
    }
  }


  eks_managed_node_groups = {
    default = {
      name = "cloud-commerce-prod-ng"

      subnet_ids = module.vpc.private_subnets

      instance_types = var.node_instance_types

      capacity_type = "ON_DEMAND"

      min_size     = var.node_min_size
      desired_size = var.node_desired_size
      max_size     = var.node_max_size

      # Explicitly ensure the node role receives the
      # permissions needed by an IPv4 EKS managed node.
      labels = {
        environment = var.environment
        workload    = "application"
      }

      tags = {
        Name        = "cloud-commerce-prod-ng"
        Project     = var.project_name
        Environment = var.environment
        ManagedBy   = "Terraform"
      }
    }
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}