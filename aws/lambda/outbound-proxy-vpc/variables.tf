variable "name" {
  description = "Name of the outbound proxy vpc"
  type        = string
}

variable "tags" {
  description = "Map of tags to assign to the outbound proxy vpc and related resources (subnets, routes, etc..)"
  type        = map(string)
  default     = {}
}

variable "eip_allocation_id" {
  description = "The elastic ip address that will be allocated to the vpc and used as the outbound proxy ip"
  type        = string
}

