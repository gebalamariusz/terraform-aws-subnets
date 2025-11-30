# AWS Subnets Terraform Module

[![Terraform Registry](https://img.shields.io/badge/Terraform%20Registry-gebalamariusz%2Fsubnets%2Faws-blue?logo=terraform)](https://registry.terraform.io/modules/gebalamariusz/subnets/aws)
[![CI](https://github.com/gebalamariusz/terraform-aws-subnets/actions/workflows/ci.yml/badge.svg)](https://github.com/gebalamariusz/terraform-aws-subnets/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/gebalamariusz/terraform-aws-subnets?display_name=tag&sort=semver)](https://github.com/gebalamariusz/terraform-aws-subnets/releases)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.7-purple.svg)](https://www.terraform.io/)

Terraform module to create AWS subnets with flexible tier-based organization and automatic route table management.

## Features

- Flexible subnet definition using CIDR as key
- User-defined tiers (public, private, database, or any custom name)
- Automatic route table creation (per tier or per subnet)
- Outputs grouped by tier for easy integration
- Compatible with [terraform-aws-vpc](https://registry.terraform.io/modules/gebalamariusz/vpc/aws) module
- **Single responsibility**: creates subnets and route tables only (routes managed separately)

## Usage

### Basic Usage with VPC Module

```hcl
module "vpc" {
  source  = "gebalamariusz/vpc/aws"
  version = "1.0.0"

  name       = "my-app"
  cidr_block = "10.0.0.0/16"
}

module "subnets" {
  source  = "gebalamariusz/subnets/aws"
  version = "2.0.0"

  name   = "my-app"
  vpc_id = module.vpc.vpc_id

  subnets = {
    "10.0.1.0/24" = {
      az     = "eu-west-1a"
      tier   = "public"
      public = true
    }
    "10.0.2.0/24" = {
      az     = "eu-west-1b"
      tier   = "public"
      public = true
    }
    "10.0.10.0/24" = {
      az     = "eu-west-1a"
      tier   = "private"
    }
    "10.0.11.0/24" = {
      az     = "eu-west-1b"
      tier   = "private"
    }
  }
}

# Add IGW route for public subnets
resource "aws_route" "public_igw" {
  route_table_id         = module.subnets.route_table_ids_by_tier["public"]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.vpc.internet_gateway_id
}
```

### Multiple VPCs from tfvars

**terraform.tfvars:**

```hcl
vpcs = {
  "production" = {
    cidr_block = "10.0.0.0/16"
    subnets = {
      "10.0.1.0/24"  = { az = "eu-west-1a", tier = "public", public = true }
      "10.0.2.0/24"  = { az = "eu-west-1b", tier = "public", public = true }
      "10.0.10.0/24" = { az = "eu-west-1a", tier = "application" }
      "10.0.11.0/24" = { az = "eu-west-1b", tier = "application" }
      "10.0.20.0/24" = { az = "eu-west-1a", tier = "database" }
      "10.0.21.0/24" = { az = "eu-west-1b", tier = "database" }
    }
  }
  "staging" = {
    cidr_block = "10.1.0.0/16"
    subnets = {
      "10.1.1.0/24"  = { az = "eu-west-1a", tier = "public", public = true }
      "10.1.10.0/24" = { az = "eu-west-1a", tier = "private" }
    }
  }
}
```

**main.tf:**

```hcl
module "vpc" {
  for_each   = var.vpcs
  source     = "gebalamariusz/vpc/aws"
  version    = "1.0.0"

  name       = each.key
  cidr_block = each.value.cidr_block
}

module "subnets" {
  for_each = var.vpcs
  source   = "gebalamariusz/subnets/aws"
  version  = "2.0.0"

  name    = each.key
  vpc_id  = module.vpc[each.key].vpc_id
  subnets = each.value.subnets
}

# Add IGW routes for public tiers
resource "aws_route" "public_igw" {
  for_each = module.subnets

  route_table_id         = each.value.route_table_ids_by_tier["public"]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.vpc[each.key].internet_gateway_id
}
```

### Custom Subnet Names

```hcl
subnets = {
  "10.0.1.0/24" = {
    az     = "eu-west-1a"
    tier   = "web"
    public = true
    name   = "web-frontend-1a"  # Custom name instead of auto-generated
  }
}
```

### Route Table Per Subnet

By default, one route table is created per tier (shared by all subnets in that tier). To create individual route tables:

```hcl
module "subnets" {
  source  = "gebalamariusz/subnets/aws"
  version = "2.0.0"

  name                        = "my-app"
  vpc_id                      = module.vpc.vpc_id
  create_route_table_per_tier = false  # Creates one RT per subnet

  subnets = {
    # ...
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.7 |
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name prefix for all resources | `string` | n/a | yes |
| vpc_id | ID of the VPC where subnets will be created | `string` | n/a | yes |
| subnets | Map of subnets to create (CIDR as key) | `map(object)` | n/a | yes |
| environment | Environment name (used in naming/tagging) | `string` | `""` | no |
| create_route_table_per_tier | Create one route table per tier (true) or per subnet (false) | `bool` | `true` | no |
| tags | Additional tags for all resources | `map(string)` | `{}` | no |

### Subnet Object Structure

| Attribute | Description | Type | Default | Required |
|-----------|-------------|------|---------|:--------:|
| az | Availability Zone | `string` | n/a | yes |
| tier | Tier name for grouping | `string` | n/a | yes |
| public | Enable public IP on launch | `bool` | `false` | no |
| name | Custom subnet name | `string` | auto-generated | no |
| tags | Additional tags for this subnet | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| subnets | Map of all subnets with their attributes |
| subnet_ids | List of all subnet IDs |
| subnet_ids_by_tier | Map of subnet IDs grouped by tier |
| subnet_arns_by_tier | Map of subnet ARNs grouped by tier |
| subnet_cidrs_by_tier | Map of subnet CIDRs grouped by tier |
| route_table_ids | List of all route table IDs |
| route_table_ids_by_tier | Map of route table IDs by tier |
| route_table_ids_by_cidr | Map of route table IDs by subnet CIDR |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| tiers | List of unique tier names |
| availability_zones | List of availability zones used |

## Adding Routes

This module creates subnets and route tables only. Add routes separately:

### Internet Gateway (public subnets)

```hcl
resource "aws_route" "public_igw" {
  route_table_id         = module.subnets.route_table_ids_by_tier["public"]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.vpc.internet_gateway_id
}
```

### NAT Gateway (private subnets)

```hcl
resource "aws_route" "private_nat" {
  route_table_id         = module.subnets.route_table_ids_by_tier["private"]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}
```

### Transit Gateway

```hcl
resource "aws_route" "to_shared_services" {
  route_table_id         = module.subnets.route_table_ids_by_tier["private"]
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
}
```

## License

MIT Licensed. See [LICENSE](LICENSE) for full details.

## Author

**HAIT** - [haitmg.pl](https://haitmg.pl)
