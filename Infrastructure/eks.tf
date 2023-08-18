locals {
  tags   = {
    Environment = "dev"
    Project = "yolo"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.16"

  cluster_name = "${var.prefix}-EKS"
  cluster_version = "1.27"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  enable_irsa = true  # Automatically provisions an OIDC provider. This is preferred to provisioning it separately.

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"  # Should change this to a custom AMI via Packer if OS baking is required.
    disk_size = 50
  }

  eks_managed_node_groups = {
    general = {
      min_size     = 2
      max_size     = 5
      desired_size = 3

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      labels = {
        Environment = "dev"
        Project = "yolo"
        Type = "on-demand"
      }
    }

    spot = {
      min_size     = 1
      max_size     = 5
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"

      labels = {
        Environment = "dev"
        Project = "yolo"
        Type = "spot"
      }
    }
  }

  tags = local.tags
}
