#  EKS connection also used for layer-2 platform

output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks_cluster.cluster_name
}

output "endpoint" {
  description = "API server endpoint URL."
  value       = module.eks_cluster.cluster_endpoint
}

output "cluster_ca" {
  description = "Base-64 encoded CA data (for kubeconfig)."
  value       = module.eks_cluster.cluster_certificate_authority_data
  sensitive   = true
}


#  OIDC & storage


output "oidc_arn" {
  description = "ARN of the EKS OIDC provider."
  value       = module.eks_cluster.eks_oidc_arn
}

output "oidc_url" {
  description = "Issuer URL of the OIDC provider."
  value       = module.eks_cluster.eks_oidc_url
}

output "efs_fs_id" {
  description = "EFS file-system id (shared static files)."
  value       = module.efs_shared_static.file_system_id
}

output "efs_ap_id" {
  description = "EFS access-point id."
  value       = module.efs_shared_static.access_point_id
}

output "csv_bucket" {
  description = "Name of the S3 bucket for CSV uploads."
  value       = module.csv_bucket.bucket
}

output "repository_arn" {
  description = "Repository arn that CI pushes to."
  value       = module.web_app_ecr.repository_arn
}

output "ecr_repo_url" {
  description = "Repository URL that CI pushes to."
  value       = module.web_app_ecr.repository_url
}

output "web_app_secret_arn" {
  description = "ARN of the web‐app SecretsManager secret."
  value       = module.web_app_secret.arn
}
