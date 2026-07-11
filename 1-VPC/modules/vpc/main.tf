resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_ipv4_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.common_tags,
    { Name = "${var.env}-vpc" }
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    var.common_tags,
    { Name = "${var.env}-igw" }
  )
}

resource "aws_subnet" "public" {
  for_each = {
    for index, az in local.selected_azs :
    az => local.public_subnets[index]
  }

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name                                                   = "${var.env}-public-${each.key}"
      "kubernetes.io/cluster/${var.env}-${var.cluster_name}" = "owned"
      "kubernetes.io/role/elb"                               = "1"
    }
  )
}

resource "aws_subnet" "private" {
  for_each = {
    for index, az in local.selected_azs :
    az => local.private_subnets[index]
  }

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = merge(
    var.common_tags,
    {
      Name                                                   = "${var.env}-private-${each.key}"
      "kubernetes.io/cluster/${var.env}-${var.cluster_name}" = "owned"
      "kubernetes.io/role/internal-elb"                      = "1"
      "karpenter.sh/discovery"                               = "${var.env}-${var.cluster_name}"
    }
  )
}

resource "aws_eip" "nat_eip" {
  tags = merge(
    var.common_tags,
    { Name = "${var.env}-nat-eip" }
  )
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = values(aws_subnet.public)[0].id

  tags = merge(
    var.common_tags,
    { Name = "${var.env}-nat" }
  )

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    var.common_tags,
    { Name = "${var.env}-public-rt" }
  )
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = merge(
    var.common_tags,
    { Name = "${var.env}-private-rt" }
  )
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
