module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc
  subnet_ids = var.private_subnets_vpc

  cluster_endpoint_private_access = "true"

  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Terraform: Node to node all ports/protocols."
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }

    egress_all = {
      description      = "Terraform: Node all egress."
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  eks_managed_node_group_defaults = {
    disk_size                  = var.disk_size
    instance_types             = [var.instance_type]
    iam_role_attach_cni_policy = true
  }

  eks_managed_node_groups = {
    "eks-${var.environment}-node" = {
      min_size     = var.ngroup_min_size
      max_size     = var.ngroup_max_size
      desired_size = var.ngroup_desired_size

      instance_types = [var.instance_type]
      capacity_type  = var.ngroup_capacity_type
    }
  }

  tags = var.tags
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
