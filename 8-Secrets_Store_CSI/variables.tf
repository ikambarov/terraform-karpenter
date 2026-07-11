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

# EKS name
variable "eks_cluster_name" {
  description = "Existing EKS cluster name"
  type        = string
  default     = "example-cluster"
}

# Default tags applied to all resources
variable "common_tags" {
  type        = map(string)
  description = "Tags applied to all managed AWS resources"
  default = {
    managed_by = "terraform"
  }
}
