output "vpc_identifier" {
  description = "VPC identifier for downstream resources"
  value       = aws_vpc.vpc.id
}

output "public_subnets_by_az" {
  description = "Public subnet IDs keyed by availability zone"
  value       = { for az in local.selected_azs : az => aws_subnet.public[az].id }
}

output "private_subnets_by_az" {
  description = "Private subnet IDs keyed by availability zone"
  value       = { for az in local.selected_azs : az => aws_subnet.private[az].id }
}
