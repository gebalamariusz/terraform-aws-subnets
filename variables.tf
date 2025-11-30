# ------------------------------------------------------------------------------
# REQUIRED VARIABLES
# ------------------------------------------------------------------------------

variable "name" {
  description = "Name prefix for all resources"
  type        = string

  validation {
    condition     = length(var.name) > 0
    error_message = "Name cannot be empty."
  }
}

variable "vpc_id" {
  description = "ID of the VPC where subnets will be created"
  type        = string

  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "VPC ID must start with 'vpc-'."
  }
}

variable "subnets" {
  description = <<-EOT
    Map of subnets to create. The key is the CIDR block for the subnet.

    Each subnet object supports:
    - az     (required) - Availability Zone (e.g., "eu-west-1a")
    - tier   (required) - Tier name for grouping (e.g., "public", "private", "database")
    - public (optional) - If true, enables map_public_ip_on_launch and creates route to IGW. Default: false
    - name   (optional) - Custom name for the subnet. Default: "{var.name}-{tier}-{az-suffix}"
    - tags   (optional) - Additional tags for this specific subnet
  EOT
  type = map(object({
    az     = string
    tier   = string
    public = optional(bool, false)
    name   = optional(string)
    tags   = optional(map(string), {})
  }))

  validation {
    condition     = length(var.subnets) > 0
    error_message = "At least one subnet must be defined."
  }

  validation {
    condition = alltrue([
      for cidr, subnet in var.subnets : can(cidrhost(cidr, 0))
    ])
    error_message = "All subnet keys must be valid CIDR blocks."
  }
}

# ------------------------------------------------------------------------------
# OPTIONAL VARIABLES
# ------------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (used in naming/tagging if provided)"
  type        = string
  default     = ""
}

variable "create_route_table_per_tier" {
  description = "If true, creates one route table per tier (shared by subnets in same tier). If false, creates one route table per subnet."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
