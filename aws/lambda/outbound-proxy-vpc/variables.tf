variable "name" {
  description = "Name/Prefix of resources created by this module."
  type        = string
}

variable "tags" {
  description = "Map of tags to assign to the created resources of this module."
  type        = map(string)
  default     = {}
}

variable "eip_allocation_id" {
  description = "The allocation id of the elastic ip address. The public ip of this eip will be used as the outbound ip of the proxy."
  type        = string
}

