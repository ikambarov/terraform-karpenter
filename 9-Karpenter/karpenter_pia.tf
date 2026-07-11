# Associate IAM role with Karpenter service account using EKS Pod Identity
resource "aws_eks_pod_identity_association" "karpenter_node_controller_identity" {
  cluster_name    = data.aws_eks_cluster.target.name
  namespace       = "kube-system"
  service_account = "karpenter"
  role_arn        = aws_iam_role.karpenter_node_provisioner_role.arn
}

# Output Pod Identity ID
output "node_controller_pod_identity_id" {
  description = "Identifier for the Pod Identity association used by the node controller"
  value       = aws_eks_pod_identity_association.karpenter_node_controller_identity.id
}
