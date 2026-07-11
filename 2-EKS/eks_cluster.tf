# Define the primary EKS cluster
resource "aws_eks_cluster" "primary" {

  # Cluster name 
  name = local.eks_cluster_name

  # Kubernetes version 
  version = var.cluster_version

  # IAM role used by EKS
  role_arn = aws_iam_role.eks_role.arn

  # VPC config
  vpc_config {

    # Private subnets 
    subnet_ids = local.private_subnets

    # Allow private endpoint access
    endpoint_private_access = var.cluster_endpoint_public_access ? false : true

    # Allow public endpoint access
    endpoint_public_access = var.cluster_endpoint_public_access ? true : false

    # List of CIDRs allowed for public access
    public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  }

  # Service CIDR range for cluster
  kubernetes_network_config {
    service_ipv4_cidr = var.cluster_service_ipv4_cidr
  }

  # Enable control plane log types
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # Ensure IAM policy attachments are completed before cluster creation
  depends_on = [
    aws_iam_role.eks_role,
    aws_iam_role.eks_node_role
  ]

  # Tags applied to the cluster
  tags = var.common_tags

  # Authentication mode for cluster access
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"

    # Grant admin permissions to cluster creator
    bootstrap_cluster_creator_admin_permissions = true
  }
}