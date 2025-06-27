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
