variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "environment_name" {
  description = "Logical environment identifier."
  type        = string
  default     = "dev"
}

variable "eks_cluster_name" {
  description = "Existing EKS cluster name."
  type        = string
  default     = "example-cluster"
}

variable "common_tags" {
  description = "Common tags."
  type        = map(string)
  default = {
    managed_by = "terraform"
  }
}
