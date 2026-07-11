terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region for the Terraform backend resources."
  type        = string
}

variable "project_name" {
  description = "Project identifier used for backend resource naming and tagging."
  type        = string
}

variable "environment_name" {
  description = "Environment identifier used for backend tagging."
  type        = string
}

variable "backend_bucket_name" {
  description = "S3 bucket name used by the numbered Terraform layers for remote state."
  type        = string
}

variable "common_tags" {
  description = "Tags applied to backend resources."
  type        = map(string)
  default     = {}
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.backend_bucket_name

  tags = merge(
    var.common_tags,
    {
      Name = var.backend_bucket_name
    }
  )
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

output "backend_bucket_name" {
  description = "S3 bucket name for Terraform remote state."
  value       = aws_s3_bucket.terraform_state.bucket
}
