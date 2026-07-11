# Lookup the VPC by its Name tag
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Lookup all subnets in the selected VPC
data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

# Filter private subnets by name prefix "dev-private"
locals {
  private_subnets = [
    for s in data.aws_subnets.all.ids :
    s if startswith(data.aws_subnet.subnets_map[s].tags["Name"], "${var.environment_name}-private")
  ]

  public_subnets = [
    for s in data.aws_subnets.all.ids :
    s if startswith(data.aws_subnet.subnets_map[s].tags["Name"], "${var.environment_name}-public")
  ]
}

# Map subnet IDs to objects to access tags
data "aws_subnet" "subnets_map" {
  for_each = toset(data.aws_subnets.all.ids)
  id       = each.value
}

# Output the VPC ID
output "vpc_id" {
  value = data.aws_vpc.selected.id
}

# Output private subnet IDs
output "private_subnet_ids" {
  value = local.private_subnets
}

# Output public subnet IDs
output "public_subnet_ids" {
  value = local.public_subnets
}
