# ------------------------------------------------------------------------------
# SUBNET OUTPUTS
# ------------------------------------------------------------------------------

output "subnets" {
  description = "Map of all subnets with their attributes (keyed by CIDR)"
  value = {
    for cidr, subnet in aws_subnet.this : cidr => {
      id                = subnet.id
      arn               = subnet.arn
      cidr_block        = subnet.cidr_block
      availability_zone = subnet.availability_zone
      tier              = var.subnets[cidr].tier
      public            = var.subnets[cidr].public
    }
  }
}

output "subnet_ids" {
  description = "List of all subnet IDs"
  value       = [for subnet in aws_subnet.this : subnet.id]
}

output "subnet_ids_by_tier" {
  description = "Map of subnet IDs grouped by tier"
  value = {
    for tier in local.unique_tiers : tier => [
      for cidr, subnet in aws_subnet.this : subnet.id if var.subnets[cidr].tier == tier
    ]
  }
}

output "subnet_arns_by_tier" {
  description = "Map of subnet ARNs grouped by tier"
  value = {
    for tier in local.unique_tiers : tier => [
      for cidr, subnet in aws_subnet.this : subnet.arn if var.subnets[cidr].tier == tier
    ]
  }
}

output "subnet_cidrs_by_tier" {
  description = "Map of subnet CIDR blocks grouped by tier"
  value = {
    for tier in local.unique_tiers : tier => [
      for cidr, subnet in var.subnets : cidr if subnet.tier == tier
    ]
  }
}

output "subnet_azs_by_tier" {
  description = "Map of availability zones grouped by tier"
  value = {
    for tier in local.unique_tiers : tier => [
      for cidr, subnet in var.subnets : subnet.az if subnet.tier == tier
    ]
  }
}

# ------------------------------------------------------------------------------
# ROUTE TABLE OUTPUTS
# ------------------------------------------------------------------------------

output "route_table_ids" {
  description = "List of all route table IDs"
  value = concat(
    [for rt in aws_route_table.per_tier : rt.id],
    [for rt in aws_route_table.per_subnet : rt.id]
  )
}

output "route_table_ids_by_tier" {
  description = "Map of route table IDs by tier (when create_route_table_per_tier = true)"
  value = {
    for tier, rt in aws_route_table.per_tier : tier => rt.id
  }
}

output "route_table_ids_by_cidr" {
  description = "Map of route table IDs by subnet CIDR (when create_route_table_per_tier = false)"
  value = {
    for cidr, rt in aws_route_table.per_subnet : cidr => rt.id
  }
}

# ------------------------------------------------------------------------------
# CONVENIENCE OUTPUTS
# ------------------------------------------------------------------------------

output "public_subnet_ids" {
  description = "List of public subnet IDs (where public = true)"
  value = [
    for cidr, subnet in aws_subnet.this : subnet.id if var.subnets[cidr].public
  ]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs (where public = false)"
  value = [
    for cidr, subnet in aws_subnet.this : subnet.id if !var.subnets[cidr].public
  ]
}

output "tiers" {
  description = "List of unique tier names"
  value       = tolist(local.unique_tiers)
}

output "availability_zones" {
  description = "List of unique availability zones used"
  value       = distinct([for cidr, subnet in var.subnets : subnet.az])
}
