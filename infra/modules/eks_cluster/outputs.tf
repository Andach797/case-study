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
