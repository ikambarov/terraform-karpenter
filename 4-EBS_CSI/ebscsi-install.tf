# Default EBS CSI addon version compatible with target EKS cluster
data "aws_eks_addon_version" "csi_default" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = data.aws_eks_cluster.target.version
}

# Latest available EBS CSI addon version for cluster
data "aws_eks_addon_version" "csi_latest" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = data.aws_eks_cluster.target.version
  most_recent        = true
}

# Deploy Amazon EBS CSI Driver as EKS addon
resource "aws_eks_addon" "csi_driver" {
  depends_on = [
    aws_iam_role.ebs_csi_role,
    aws_eks_pod_identity_association.ebs_csi
  ]

  cluster_name             = data.aws_eks_cluster.target.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = data.aws_eks_addon_version.csi_latest.version
  service_account_role_arn = aws_iam_role.ebs_csi_role.arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # Merge common tags with addon-specific tags
  tags = merge(
    var.common_tags,
    {
      Name      = "${var.environment_name}-csi-addon"
      Component = "Amazon EBS CSI Driver"
    }
  )
}

# Outputs EBS CSI addon version info and identifiers
output "csi_addon_default_version" {
  description = "Default EBS CSI addon version for the cluster"
  value       = data.aws_eks_addon_version.csi_default.version
}

output "csi_addon_latest_version" {
  description = "Latest available EBS CSI addon version for the cluster"
  value       = data.aws_eks_addon_version.csi_latest.version
}

output "csi_addon_arn" {
  description = "ARN of the installed EBS CSI addon"
  value       = aws_eks_addon.csi_driver.arn
}

output "csi_addon_id" {
  description = "ID of the installed EBS CSI addon"
  value       = aws_eks_addon.csi_driver.id
}
