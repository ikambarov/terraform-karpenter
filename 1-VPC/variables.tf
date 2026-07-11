# AWS region where resources will be deployed
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

# Deployment environment (used in resource names and tags)
variable "environment_name" {
  description = "Deployment environment name"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "EKS cluster short name used for Kubernetes discovery tags"
  type        = string
  default     = "example-cluster"
}

# VPC network CIDR
variable "vpc_network_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Number of bits to add to VPC CIDR for subnetting (e.g., 8 → /24)
variable "subnet_mask_bits" {
  description = "Number of bits for subnet mask"
  type        = number
  default     = 8
}

# Map of global tags for resources
variable "tags" {
  description = "Default tags applied to all resources"
  type        = map(string)
  default = {
    managed_by   = "terraform"
    project_name = "example-platform"
    environment  = "dev"
  }
}
