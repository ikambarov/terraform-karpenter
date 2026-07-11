# Terraform AWS VPC Module
Sample Terraform module for provisioning an AWS VPC with public and private subnets, Internet Gateway, NAT Gateway, and routing.

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"
  env                = "dev"
  vpc_ipv4_cidr      = "10.0.0.0/16"
  subnet_prefix_bits = 8
}
```

## Required Inputs

| Name            | Description                       |
|-----------------|-----------------------------------|
| `vpc_ipv4_cidr` | CIDR block for the VPC            |
| `subnet_prefix_bits` | Number of bits used to derive subnet CIDRs |

## Optional Inputs

| Name          | Description                                   |
|---------------|-----------------------------------------------|
| `env`         | Environment name used for resource naming    |
| `common_tags` | Map of tags applied to all resources         |

## Outputs

| Name                     | Description                       |
|--------------------------|-----------------------------------|
| `vpc_identifier`         | ID of the created VPC             |
| `public_subnets`         | List of public subnet IDs         |
| `private_subnets`        | List of private subnet IDs        |
| `public_subnets_by_az`   | Map of availability zone to public subnet ID |
