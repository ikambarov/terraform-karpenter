# Install EKS Pod Identity Agent addon
resource "aws_eks_addon" "pod_id_agent" {
  cluster_name  = data.aws_eks_cluster.target.name
  addon_name    = "eks-pod-identity-agent"
  addon_version = data.aws_eks_addon_version.pod_id_current.version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

# Fetch default addon version compatible with the cluster EKS version
data "aws_eks_addon_version" "pod_id_base" {
  addon_name         = "eks-pod-identity-agent"
  kubernetes_version = data.aws_eks_cluster.target.version
}

# Export default compatible addon version
output "eks_pod_identity_default_version" {
  value = data.aws_eks_addon_version.pod_id_base.version
}

# Fetch latest compatible addon version for the cluster
data "aws_eks_addon_version" "pod_id_current" {
  addon_name         = "eks-pod-identity-agent"
  kubernetes_version = data.aws_eks_cluster.target.version
  most_recent        = true
}

# Export latest compatible addon version
output "eks_pod_identity_latest_version" {
  value = data.aws_eks_addon_version.pod_id_current.version
}

# Export addon ARN
output "eks_pod_identity_addon_arn" {
  value = aws_eks_addon.pod_id_agent.arn
}

# Export addon resource ID
output "eks_pod_identity_addon_id" {
  value = aws_eks_addon.pod_id_agent.id
}