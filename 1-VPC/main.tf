module "vpc" {
  source             = "./modules/vpc"
  env                = var.environment_name
  vpc_ipv4_cidr      = var.vpc_network_cidr
  subnet_prefix_bits = var.subnet_mask_bits
  common_tags        = var.tags
}
