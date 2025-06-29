# TODO: Format also for terraform
module "network" {
  source               = "../modules/vpc"
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

  subnet_ids = module.network.private_subnet_ids

  project_tag = var.project_tag
  environment = var.environment

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # one on-demand and one spot
  managed_node_groups = {
    on_demand = {
      capacity_type  = "ON_DEMAND"
      instance_types = ["t3.micro"]
      desired_size   = 2
      min_size       = 2
      max_size       = 3
      labels         = { workload = "free" }
    },
    spot = {
      capacity_type  = "SPOT"
      instance_types = ["t3.small"]
      desired_size   = 1
      min_size       = 1
      max_size       = 3
      labels         = { workload = "spot" }
    }
  }

  tags = var.tags
}

module "csv_bucket" {
  source          = "../modules/s3_bucket"
  name            = "andac-case-csv-uploads-${var.environment}"
  days_to_glacier = 30
  force_destroy   = true

  tags = merge(var.tags, {
    Name = "csv-uploads-${var.environment}"
  })
}

module "web_app_irsa" {
  source = "../modules/irsa_sa"

  name_prefix = "${var.project_tag}-${var.environment}-web-app"
  namespace   = "default"
  bucket_arn  = module.csv_bucket.arn

  oidc_arn = module.eks_cluster.eks_oidc_arn
  oidc_url = replace(module.eks_cluster.eks_oidc_url, "https://", "")

  secret_arns = [module.web_app_secret.arn]
  tags        = var.tags
}

module "efs_shared_static" {
  source = "../modules/efs"

  name     = "${var.project_tag}-${var.environment}-static"
  vpc_id   = module.network.vpc_id
  vpc_cidr = var.vpc_cidr

  subnet_ids = module.network.private_subnet_ids
  allowed_security_group_ids = concat(
    [module.eks_cluster.cluster_security_group_id],
    module.eks_cluster.worker_sg_ids
  )
  create_access_point = true
  tags                = var.tags
}

module "web_app_ecr" {
  source = "../modules/ecr"
  name   = "web-app-${var.environment}"
  tags   = var.tags
}

module "web_app_secret" {
  source      = "../modules/secrets_manager"
  name        = "${var.project_tag}-${var.environment}-web-app"
  description = "Secrets for the web app"
  secret_kv = {
    CSV_BUCKET = module.csv_bucket.bucket
  }
  tags = var.tags
}

# Preparing for environment maybe changed with ci/cd
resource "helm_release" "web_nginx" {
  name      = "web-nginx"
  chart     = "${path.module}/../../charts/web-nginx"
  version   = "0.1.0"
  namespace = "default"

  values = [
    yamlencode({
      image = {
        repository = module.web_app_ecr.repository_url
        tag        = var.image_tag
      }

      secretArn = module.web_app_secret.arn

      efs = {
        fileSystemId  = module.efs_shared_static.file_system_id
        accessPointId = module.efs_shared_static.access_point_id
      }
    })
  ]

  depends_on = [module.eks_cluster]
}

module "gha_push_role" {
  source = "../modules/gha_ci_role"

  repo_owner = "Andach797"
  repo_name  = "case-study"

  ecr_repo_arn = module.web_app_ecr.repository_arn

  role_name = "case-gha-ecr-push"
  tags      = var.tags
}

module "gha_tf_role" {
  source              = "../modules/gha_tf_role"
  repo_owner          = "Andach797"
  repo_name           = "case-study"
  backend_bucket      = "andac-tfstate-dev"
  csv_bucket          = module.csv_bucket.bucket
  dynamodb_table_name = "andac-tfstate-lock-dev"
  role_name           = "case-gha-terraform"
  tags = {
    Environment = var.environment
    Project     = var.project_tag
  }

}
