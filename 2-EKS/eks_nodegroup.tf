# EKS Node Group Deployment
resource "aws_eks_node_group" "node_group" {

  # Associate with the target EKS cluster
  cluster_name = aws_eks_cluster.primary.name

  # Unique identifier for this node group
  node_group_name = "${local.prefix}-node-group"

  # IAM role assigned to EC2 nodes
  node_role_arn = aws_iam_role.eks_node_role.arn

  # Deploy nodes in private subnet IDs
  subnet_ids = local.private_subnets

  # Node instance types selection
  instance_types = var.node_instance_types

  # Specify node capacity type: ON_DEMAND or SPOT
  capacity_type = var.node_capacity_type

  # Use Amazon Linux 2023 optimized AMI
  ami_type = "AL2023_x86_64_STANDARD"

  # Node root volume in GiB
  disk_size = var.node_disk_size

  # Scaling parameters for the node group
  scaling_config {
    desired_size = 2 # Default number of nodes
    min_size     = 1 # Minimum nodes allowed
    max_size     = 2 # Maximum nodes allowed
  }

  # Limit max unavailable nodes during updates
  update_config {
    max_unavailable_percentage = 50
  }

  # Automatically update nodes when AMI changes
  force_update_version = true

  # Kubernetes labels for scheduling and identification
  labels = {
    env = var.environment_name
  }

  # Resource tags for AWS and tracking
  tags = merge(var.common_tags, {
    Name        = "${local.prefix}-node-group"
    Environment = var.environment_name
  })

  # Ensure IAM policies are attached before node creation
  depends_on = [
    aws_iam_role.eks_node_role
  ]
}