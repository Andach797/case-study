output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks_cluster.cluster_name
}

output "eks_cluster_endpoint" {
  description = "The API endpoint for EKS cluster"
  value       = module.eks_cluster.cluster_endpoint
}

output "eks_cluster_kubeconfig" {
  description = "Kubeconfig for EKS cluster"
  value       = module.eks_cluster.kubeconfig
  sensitive   = true
}

# EFS for shared static files
output "efs_file_system_id" {
  description = "ID of the EFS file system used for shared static volume"
  value       = module.efs_shared_static.file_system_id
}

output "efs_access_point_id" {
  description = "Access-point ID used by the EFS CSI driver"
  value       = module.efs_shared_static.access_point_id
}

output "gha_role_arn" {
  value = module.gha_push_role.role_arn
}

output "gha_tf_role_arn" {
  value = module.gha_tf_role.role_arn
}
