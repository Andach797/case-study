module "network" {
  source  = "../modules/vpc"
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  create_nat_gateway = true
  project_tag        = var.project_tag
  environment        = var.environment

  tags = var.tags
}

module "eks_cluster" {
  source       = "../modules/eks_cluster"
  cluster_name = "${var.project_tag}-${var.environment}-eks"
  k8s_version  = "1.33"

  subnet_ids   = module.network.private_subnet_ids

  project_tag  = var.project_tag
  environment  = var.environment

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # one on-demand and one spot
  managed_node_groups = {
    on_demand = {
      capacity_type  = "ON_DEMAND"
      instance_types = ["t3.micro"]
      desired_size   = 1
      min_size       = 1
      max_size       = 2
      labels         = { workload = "free" }
    },
    spot = {
      capacity_type  = "SPOT"
      instance_types = ["t3.small"]
      desired_size   = 0
      min_size       = 0
      max_size       = 3
      labels         = { workload = "spot" }
    }
  }

  tags = var.tags
}