output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.cluster.name
}

output "cluster_endpoint" {
  description = "API server endpoint of the EKS cluster"
  value       = aws_eks_cluster.cluster.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded CA certificate for the EKS cluster"
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
}

# Renders a kubeconfig using the template file for esay access
locals {
  kubeconfig = templatefile("${path.module}/templates/kubeconfig.tpl", {
    endpoint                   = aws_eks_cluster.cluster.endpoint,
    certificate_authority_data = aws_eks_cluster.cluster.certificate_authority[0].data,
    cluster_name               = aws_eks_cluster.cluster.name
  })
}

output "kubeconfig" {
  description = "Kubeconfig file content for this cluster (useful for kubectl access)"
  value       = local.kubeconfig
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS control plane"
  value       = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}

output "eks_oidc_arn" {
  value       = aws_iam_openid_connect_provider.eks_oidc.arn
  description = "ARN of the cluster OIDC provider"
}

output "eks_oidc_url" {
  value       = aws_iam_openid_connect_provider.eks_oidc.url
  description = "URL of the cluster OIDC provider"
}