data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

data "aws_eks_cluster" "target" {
  name = var.eks_cluster_name
}
