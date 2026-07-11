# Fetch available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Locals for AZs and subnet CIDRs
locals {
  # Pick the first 3 AZs
  selected_azs = slice(data.aws_availability_zones.available.names, 0, 3)

  # Generate public subnets
  public_subnets = [
    for idx, az in local.selected_azs : cidrsubnet(var.vpc_ipv4_cidr, var.subnet_prefix_bits, idx)
  ]

  # Generate private subnets with offset to avoid overlap
  private_subnets = [
    for idx, az in local.selected_azs : cidrsubnet(var.vpc_ipv4_cidr, var.subnet_prefix_bits, idx + length(local.selected_azs))
  ]
}