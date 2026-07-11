# EKS Pod Identity Association for Amazon EBS CSI Driver
resource "aws_eks_pod_identity_association" "ebs_csi" {
  cluster_name    = data.aws_eks_cluster.target.name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"
  role_arn        = aws_iam_role.ebs_csi_role.arn
}

# Output EBS CSI Pod Identity Association ARN
output "ebs_csi_pod_identity_association_arn" {
  description = "ARN of the EBS CSI Driver Pod Identity Association"
  value       = aws_eks_pod_identity_association.ebs_csi.association_arn
}