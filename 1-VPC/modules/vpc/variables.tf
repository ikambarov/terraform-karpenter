variable "env" {
  type        = string
  description = "Environment identifier (e.g. dev, staging, prod)"
  default     = "dev"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster short name used for Kubernetes discovery tags"
  default     = "example-cluster"
}

variable "vpc_ipv4_cidr" {
  type        = string
  description = "Primary IPv4 CIDR range assigned to the VPC"
  default     = "10.0.0.0/16"
}

variable "subnet_prefix_bits" {
  type        = number
  description = "Additional CIDR bits used when deriving subnet ranges from the VPC block"
  default     = 8
}

variable "common_tags" {
  type        = map(string)
  description = "Tags applied to all managed AWS resources"
  default = {
    managed_by = "terraform"
  }
}
