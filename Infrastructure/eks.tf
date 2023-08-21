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
      min_size     = 1
      max_size     = 3
      desired_size = 1

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      labels = {
        Environment = "dev"
        Project = "yolo"
        Type = "on-demand"
      }

      tags = {
        "k8s.io/cluster-autoscaler/enabled"                  = "true"
        "k8s.io/cluster-autoscaler/${var.prefix}-EKS"        = "owned"
      }
    }

    spot = {
      min_size     = 1
      max_size     = 3
      desired_size = 1

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"

      labels = {
        Environment = "dev"
        Project = "yolo"
        Type = "spot"
      }

      tags = {
        "k8s.io/cluster-autoscaler/enabled"                       = "true"
        "k8s.io/cluster-autoscaler/${var.prefix}-EKS"        = "owned"
      }
    }
  }
}

locals {
  eks_asg_tags = {
    "k8s.io/cluster-autoscaler/enabled" : true
    "k8s.io/cluster-autoscaler/${var.prefix}-EKS" : "owned"
  }
}

resource "aws_autoscaling_group_tag" "nodegroup1" {
  for_each               = local.eks_asg_tags
  autoscaling_group_name = element(module.eks.eks_managed_node_groups_autoscaling_group_names, 0)

  tag {
    key                 = each.key
    value               = each.value
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group_tag" "nodegroup2" {
  for_each               = local.eks_asg_tags
  autoscaling_group_name = element(module.eks.eks_managed_node_groups_autoscaling_group_names, 1)

  tag {
    key                 = each.key
    value               = each.value
    propagate_at_launch = true
  }
}
