# Lookup existing EKS cluster by name
data "aws_eks_cluster" "target" {
  name = var.eks_cluster_name
}

# Retrieve authentication token for the EKS cluster
data "aws_eks_cluster_auth" "eks_token" {
  name = data.aws_eks_cluster.target.name
}
