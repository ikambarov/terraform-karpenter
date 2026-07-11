# Local values for consistent naming and references across EKS resources
locals {
  # Environment identifier (from variable)
  environment = var.environment_name

  # Standardized prefix (can be customized)
  prefix = local.environment

  # Full EKS cluster name for use in resource naming and tagging
  eks_cluster_name = "${local.prefix}-${var.cluster_name}"
}