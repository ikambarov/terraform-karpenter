data "aws_eks_cluster" "target" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "eks_token" {
  name = data.aws_eks_cluster.target.name
}
