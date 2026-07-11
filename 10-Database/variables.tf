variable "aws_region" {
  description = "AWS region where database resources are deployed."
  type        = string
  default     = "us-east-1"
}

variable "environment_name" {
  description = "Logical environment identifier used in resource names and tags."
  type        = string
  default     = "dev"
}

variable "vpc_name" {
  description = "Existing VPC Name tag."
  type        = string
  default     = "example-vpc"
}

variable "eks_cluster_name" {
  description = "Existing EKS cluster name allowed to reach the database."
  type        = string
  default     = "example-cluster"
}

variable "database_name" {
  description = "Initial MySQL database name for Client Tracker."
  type        = string
  default     = "client_tracker"
}

variable "database_username" {
  description = "Master username for the RDS MySQL instance."
  type        = string
  default     = "admin"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Allocated RDS storage in GiB."
  type        = number
  default     = 20
}

variable "common_tags" {
  description = "Tags applied to database resources."
  type        = map(string)
  default = {
    managed_by = "terraform"
  }
}
