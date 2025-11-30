# ------------------------------------------------------------------------------
# LOCAL VALUES
# ------------------------------------------------------------------------------

locals {
  # Build resource name prefix
  name_prefix = var.environment != "" ? "${var.name}-${var.environment}" : var.name

  # Common tags for all resources
  common_tags = merge(
    var.tags,
    {
      ManagedBy = "terraform"
      Module    = "terraform-aws-subnets"
    }
  )

  # Generate subnet names (used in multiple places)
  subnet_names = {
    for cidr, subnet in var.subnets : cidr =>
    subnet.name != null ? subnet.name : "${local.name_prefix}-${subnet.tier}-${substr(subnet.az, -1, 1)}"
  }

  # Extract unique tiers for route table creation
  unique_tiers = toset([for cidr, subnet in var.subnets : subnet.tier])

  # Validate: all subnets in the same tier must have the same 'public' value
  # This prevents accidentally exposing "private" subnets via shared route table
  tier_public_consistency = {
    for tier in local.unique_tiers : tier => distinct([
      for cidr, subnet in var.subnets : subnet.public if subnet.tier == tier
    ])
  }
  mixed_tiers = [
    for tier, public_values in local.tier_public_consistency : tier
    if length(public_values) > 1
  ]

  # Determine which tiers are public (have at least one public subnet)
  public_tiers = toset([
    for cidr, subnet in var.subnets : subnet.tier if subnet.public
  ])

  # Map of route tables to create (per tier or per subnet)
  route_tables_per_tier = var.create_route_table_per_tier ? {
    for tier in local.unique_tiers : tier => {
      name      = "${local.name_prefix}-${tier}"
      is_public = contains(local.public_tiers, tier)
    }
  } : {}

  route_tables_per_subnet = !var.create_route_table_per_tier ? {
    for cidr, subnet in var.subnets : cidr => {
      name      = local.subnet_names[cidr]
      is_public = subnet.public
    }
  } : {}
}

# ------------------------------------------------------------------------------
# SUBNETS
# ------------------------------------------------------------------------------

resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id                  = var.vpc_id
  cidr_block              = each.key
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.public

  tags = merge(
    local.common_tags,
    {
      Name = local.subnet_names[each.key]
      Tier = each.value.tier
    },
    each.value.tags
  )

  lifecycle {
    precondition {
      condition     = !each.value.public || var.internet_gateway_id != null
      error_message = "Subnet ${each.key} has public = true but internet_gateway_id is not provided. Public subnets require an Internet Gateway for routing."
    }
  }
}

# ------------------------------------------------------------------------------
# ROUTE TABLES (PER TIER)
# ------------------------------------------------------------------------------

resource "aws_route_table" "per_tier" {
  for_each = local.route_tables_per_tier

  vpc_id = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = each.value.name
      Tier = each.key
    }
  )

  lifecycle {
    precondition {
      condition     = length(local.mixed_tiers) == 0
      error_message = "All subnets in the same tier must have the same 'public' value when using per-tier route tables. Mixed tiers found: ${join(", ", local.mixed_tiers)}. Use create_route_table_per_tier = false for mixed configurations."
    }
  }
}

# ------------------------------------------------------------------------------
# ROUTE TABLES (PER SUBNET)
# ------------------------------------------------------------------------------

resource "aws_route_table" "per_subnet" {
  for_each = local.route_tables_per_subnet

  vpc_id = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = each.value.name
    }
  )
}

# ------------------------------------------------------------------------------
# ROUTES TO INTERNET GATEWAY (FOR PUBLIC SUBNETS/TIERS)
# ------------------------------------------------------------------------------

resource "aws_route" "igw_per_tier" {
  for_each = {
    for tier, rt in local.route_tables_per_tier : tier => rt if rt.is_public && var.internet_gateway_id != null
  }

  route_table_id         = aws_route_table.per_tier[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.internet_gateway_id
}

resource "aws_route" "igw_per_subnet" {
  for_each = {
    for cidr, rt in local.route_tables_per_subnet : cidr => rt if rt.is_public && var.internet_gateway_id != null
  }

  route_table_id         = aws_route_table.per_subnet[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.internet_gateway_id
}

# ------------------------------------------------------------------------------
# ROUTE TABLE ASSOCIATIONS
# ------------------------------------------------------------------------------

resource "aws_route_table_association" "per_tier" {
  for_each = var.create_route_table_per_tier ? var.subnets : {}

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.per_tier[each.value.tier].id
}

resource "aws_route_table_association" "per_subnet" {
  for_each = !var.create_route_table_per_tier ? var.subnets : {}

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.per_subnet[each.key].id
}
