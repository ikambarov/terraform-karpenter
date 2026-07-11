# Trust policy allowing EC2 to assume the node role
data "aws_iam_policy_document" "ec2_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM role assumed by worker nodes provisioned by the controller
resource "aws_iam_role" "karpenter_node_instance_role" {
  name               = "${var.environment_name}-karpenter-node-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust_policy.json
  tags               = var.common_tags
}

# Attach required AWS-managed policies to the node role
resource "aws_iam_role_policy_attachment" "karpenter_node_managed_policy_attachments" {
  for_each = {
    worker = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    ecr    = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
    cni    = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    ssm    = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  role       = aws_iam_role.karpenter_node_instance_role.name
  policy_arn = each.value
}

# Grant EKS cluster access to EC2 nodes via IAM role mapping
resource "aws_eks_access_entry" "karpenter_node_ec2_access" {
  cluster_name  = data.aws_eks_cluster.target.name
  principal_arn = aws_iam_role.karpenter_node_instance_role.arn
  type          = "EC2_LINUX"
}

# Output node role name
output "node_role_name" {
  description = "Name of the IAM role assumed by EC2 worker nodes"
  value       = aws_iam_role.karpenter_node_instance_role.name
}

# Output node role ARN
output "node_role_arn" {
  description = "ARN of the IAM role assumed by EC2 worker nodes"
  value       = aws_iam_role.karpenter_node_instance_role.arn
}

# Output node role unique identifier
output "node_role_id" {
  description = "Stable unique identifier for the EC2 node IAM role"
  value       = aws_iam_role.karpenter_node_instance_role.unique_id
}
