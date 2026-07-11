# Get latest ExternalDNS addon version for the EKS cluster
data "aws_eks_addon_version" "dns_latest" {
  addon_name         = "external-dns"
  kubernetes_version = data.aws_eks_cluster.target.version
  most_recent        = true
}

# Deploy ExternalDNS as EKS addon
resource "aws_eks_addon" "dns_driver" {
  depends_on = [
    aws_iam_role.dns_controller_role,
    aws_eks_pod_identity_association.dns_controller
  ]

  cluster_name             = data.aws_eks_cluster.target.name
  addon_name               = "external-dns"
  addon_version            = data.aws_eks_addon_version.dns_latest.version
  service_account_role_arn = aws_iam_role.dns_controller_role.arn
  configuration_values = jsonencode({
    domainFilters      = var.domain_filters
    sources            = var.sources
    triggerLoopOnEvent = true
    txtOwnerId         = data.aws_eks_cluster.target.name
  })
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # Merge managed tags for consistent tagging
  tags = merge(
    var.common_tags,
    {
      Component = "ExternalDNS"
      Project   = var.environment_name
    }
  )
}

# Outputs ExternalDNS addon details
output "dns_addon_version" {
  description = "Version of the deployed ExternalDNS addon"
  value       = aws_eks_addon.dns_driver.addon_version
}

output "dns_addon_arn" {
  description = "ARN of the ExternalDNS addon"
  value       = aws_eks_addon.dns_driver.arn
}

output "dns_addon_id" {
  description = "ID of the ExternalDNS addon"
  value       = aws_eks_addon.dns_driver.id
}
