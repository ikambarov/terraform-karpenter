# AWS region configuration
variable "aws_region" {
  description = "Specifies the AWS region for deploying resources."
  type        = string
  default     = "us-east-1"
}

# Environment and business context
variable "environment_name" {
  description = "Logical environment identifier used in resource names and tagging."
  type        = string
  default     = "dev"
}

# EKS VPC
variable "vpc_name" {
  description = "Existing VPC Name to provision cluster on"
  type        = string
  default     = "example-vpc"
}

# EKS cluster settings
variable "cluster_name" {
  description = "EKS cluster identifier, used as a prefix in related resources."
  type        = string
  default     = "example-cluster"
}

# EKS cluster version
variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane (e.g., 1.28, 1.29)."
  type        = string
  default     = 1.34
}

# Cluster CIDR
variable "cluster_service_ipv4_cidr" {
  description = "CIDR block for Kubernetes services. Optional; leave null to use AWS default."
  type        = string
  default     = null
}

# Public access status 
variable "cluster_endpoint_public_access" {
  description = "Enable public endpoint access for the EKS control plane."
  type        = bool
  default     = true
}

# Allowed IPs
variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks permitted to reach the public EKS API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Default tags applied to all resources
variable "common_tags" {
  type        = map(string)
  description = "Tags applied to all managed AWS resources"
  default = {
    managed_by = "terraform"
  }
}

# Node group configuration
variable "node_instance_types" {
  description = "EC2 instance types used for EKS worker nodes."
  type        = list(string)
  default     = ["t3.medium"]
}

# Node capacity type
variable "node_capacity_type" {
  description = "Capacity type for node group instances: ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"
}

# Node disk size
variable "node_disk_size" {
  description = "Root volume size in GiB for worker nodes."
  type        = number
  default     = 40
}
