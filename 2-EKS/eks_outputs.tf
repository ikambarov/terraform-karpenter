# API endpoint to interact with the EKS cluster
output "cluster_api_endpoint" {
  description = "API server endpoint for the EKS cluster"
  value       = aws_eks_cluster.primary.endpoint
}

# Kubernetes version running in the cluster
output "cluster_k8s_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = aws_eks_cluster.primary.version
}

# Name of the EKS cluster
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.primary.name
}

# Base64 encoded certificate authority for kubeconfig
output "cluster_ca_certificate" {
  description = "Base64 encoded certificate authority for the cluster"
  value       = aws_eks_cluster.primary.certificate_authority[0].data
}

# Command to configure local kubeconfig for the cluster
output "kubectl_config_command" {
  description = "Command to configure kubeconfig for this EKS cluster"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${local.eks_cluster_name}"
}
