# IAM role for EKS control plane
resource "aws_iam_role" "eks_role" {
  name = "${local.prefix}-eks-role"

  # Trust relationship allowing EKS service to assume this role
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
  {
   "Effect": "Allow",
   "Principal": {
    "Service": "eks.amazonaws.com"
   },
   "Action": "sts:AssumeRole"
  }
 ]
}
EOF

  # Attach tags
  tags = var.common_tags
}

# Fetch the managed IAM policy for EKS control plane
data "aws_iam_policy" "eks_cluster_policy" {
  name = "AmazonEKSClusterPolicy"
}

# Attach managed IAM policy to EKS control plane
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = data.aws_iam_policy.eks_cluster_policy.arn
}

# IAM role for EKS worker nodes
resource "aws_iam_role" "eks_node_role" {
  name = "${local.prefix}-eks-node-role"

  # Trust relationship allowing EKS nodes to assume this role
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
  {
   "Effect": "Allow",
   "Principal": {
    "Service": "ec2.amazonaws.com"
   },
   "Action": "sts:AssumeRole"
  }
 ]
}
EOF

  # Attach tags
  tags = var.common_tags
}

# Fetch IAM policies for EKS worker nodes
data "aws_iam_policy" "registry_policy" {
  name = "AmazonEC2ContainerRegistryReadOnly"
}

data "aws_iam_policy" "cni_policy" {
  name = "AmazonEKS_CNI_Policy"
}

data "aws_iam_policy" "node_policy" {
  name = "AmazonEKSWorkerNodePolicy"
}

# Attach all necessary managed policies for EKS worker nodes
resource "aws_iam_role_policy_attachment" "node_registry" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = data.aws_iam_policy.registry_policy.arn
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = data.aws_iam_policy.cni_policy.arn
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = data.aws_iam_policy.node_policy.arn
}