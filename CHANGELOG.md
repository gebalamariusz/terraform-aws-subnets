# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-11-30

### BREAKING CHANGES

- **Removed** `internet_gateway_id` variable
- **Removed** `create_igw_routes` variable
- **Removed** automatic IGW route creation for public subnets
- **Removed** precondition validations for IGW and mixed tiers

### Why this change?

The module now follows **single responsibility principle**:
- `terraform-aws-subnets` creates subnets and route tables only
- Routes (IGW, NAT, TGW, etc.) should be managed by dedicated modules like `terraform-aws-routes`

This eliminates the "known only after apply" bugs and makes modules more composable.

### Migration from v1.x

```hcl
# Before (v1.x) - IGW routes were created automatically
module "subnets" {
  source              = "gebalamariusz/subnets/aws"
  version             = "1.x.x"
  internet_gateway_id = module.vpc.internet_gateway_id
  # ...
}

# After (v2.0.0) - Create IGW routes separately
module "subnets" {
  source  = "gebalamariusz/subnets/aws"
  version = "2.0.0"
  # internet_gateway_id removed - no longer needed
  # ...
}

# Add IGW routes using aws_route resource or terraform-aws-routes module
resource "aws_route" "public_igw" {
  for_each = module.subnets.route_table_ids_by_tier

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.vpc.internet_gateway_id
}
```

## [1.3.0] - 2025-11-30 [SKIPPED]

Not released - superseded by v2.0.0.

## [1.2.0] - 2025-11-30 [DEPRECATED]

### Fixed

- ~~Changed `internet_gateway_id` default from `""` to `null`~~ - **This fix was incorrect, use v2.0.0**

## [1.1.0] - 2025-11-28

### Added

- Precondition validation: all subnets in the same tier must have the same `public` value when using per-tier route tables
- Precondition validation: `internet_gateway_id` is required when any subnet has `public = true`

### Changed

- Extracted subnet name generation to `local.subnet_names` for DRY code

## [1.0.0] - 2025-11-28

### Added

- Initial release
- Flexible subnet creation using CIDR as map key
- User-defined tiers for subnet grouping
- Route table creation (per tier or per subnet)
- Public subnet support with automatic IGW routing
- Outputs grouped by tier
- Full compatibility with terraform-aws-vpc module
- CI/CD with GitHub Actions
- Comprehensive documentation
