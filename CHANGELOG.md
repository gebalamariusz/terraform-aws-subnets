# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
