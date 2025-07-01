#  Networking
module "network" {
  source               = "../../modules/vpc"
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  create_nat_gateway   = true

  project_tag = var.project_tag
  environment = var.environment
  tags        = var.tags
}

#  EKS control-plane + managed node groups

module "eks_cluster" {
  source       = "../../modules/eks_cluster"
  cluster_name = "${var.project_tag}-${var.environment}-eks"
  k8s_version  = "1.33"

  subnet_ids = module.network.private_subnet_ids

  project_tag = var.project_tag
  environment = var.environment

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  managed_node_groups = {
    on_demand = {
      capacity_type  = "ON_DEMAND"
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 2
      max_size       = 3
    },
    spot = {
      capacity_type  = "SPOT"
      instance_types = ["t3.medium"]
      desired_size   = 1
      min_size       = 1
      max_size       = 3
    }
  }

  tags = var.tags
}

# Blcoks needed by layer-2 platform

module "efs_shared_static" {
  source = "../../modules/efs"

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

module "csv_bucket" {
  source          = "../../modules/s3_bucket"
  name            = "andac-${var.project_tag}-csv-uploads-${var.environment}"
  days_to_glacier = 30
  force_destroy   = true

  tags = merge(var.tags, { Name = "csv-uploads-${var.environment}" })
}

module "web_app_secret" {
  source      = "../../modules/secrets_manager"
  name        = "${var.project_tag}-${var.environment}-web-app-secret"
  description = "Secrets for the web app"
  secret_kv = {
    CSV_BUCKET = module.csv_bucket.bucket
  }
  tags = var.tags
}


module "web_app_ecr" {
  source = "../../modules/ecr"
  name   = "web-app-${var.environment}"
  tags   = var.tags
}

# GitHub-Actions roles for CI & Terraform

module "gha_ci_role" {
  source       = "../../modules/gha_ci_role"
  repo_owner   = "Andach797"
  repo_name    = "case-study"
  ecr_repo_arn = module.web_app_ecr.repository_arn
  role_name    = "case-gha-ecr-push"
  tags         = var.tags
}

module "gha_tf_role" {
  source              = "../../modules/gha_tf_role"
  repo_owner          = "Andach797"
  repo_name           = "case-study"
  backend_bucket      = "andac-tfstate-dev"
  csv_bucket          = module.csv_bucket.bucket
  dynamodb_table_name = "andac-tfstate-lock-dev"
  role_name           = "case-gha-terraform"
  oidc_provider_arn   = module.gha_ci_role.oidc_provider_arn
  tags                = var.tags
}
# Write charts/web-nginx/environments/values-dev.yaml from tf outputs

resource "local_file" "web_nginx_values_dev" {
  filename = "${path.root}/../../../charts/web-nginx/environments/values-dev.yaml"
  provisioner "local-exec" {
    command = "mkdir -p $(dirname ${self.filename})"
  }

  content = yamlencode({
    image = {
      repository = module.web_app_ecr.repository_url
      tag        = "latest"
    }

    secretArn = module.web_app_secret.arn

    efs = {
      fileSystemId  = module.efs_shared_static.file_system_id
      accessPointId = module.efs_shared_static.access_point_id
    }
  })

  file_permission = "0644"

  # generate file whenever its inputs change
  depends_on = [
    module.web_app_ecr,
    module.web_app_secret,
    module.efs_shared_static
  ]
}
