terraform {
  # Enforce Terraform version compatibility
  required_version = ">= 1.0.0"

  # Specify providers required for this configuration along with version requirements
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }

  # Configure remote state storage in S3
  backend "s3" {}
}
