output "vpc_id" {
  value       = module.vpc.vpc_identifier
  description = "VPC ID"
}

output "public_subnet_map" {
  value       = module.vpc.public_subnets_by_az
  description = "Public subnets AZ maps"
}

output "private_subnet_map" {
  value       = module.vpc.private_subnets_by_az
  description = "Public subnets AZ maps"
}
