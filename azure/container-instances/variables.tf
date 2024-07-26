variable "name" {
  description = "Name of resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of resource group"
  type        = string
}

variable "dns_resource_group" {
  description = "Resource group where the DNS zone is located."
  type        = string
  default = null
}

variable "dns_a_record_name" {
  description = "The name of the DNS A record."
  type        = string
  default = null
}

variable "dns_zone_name" {
  description = "The name of the DNS zone."
  type        = string
  default = null
}

variable "dns_record_ttl" {
  description = "The TTL of the DNS record."
  type        = number
  default     = 300
}

variable "location" {
  description = "The Azure region where the resources should be created."
  type        = string
}

variable "registry_credential" {
  description = "The credentials for the container registry."
  type = object({
    username = string
    password = string
    server   = string
  })
  default = null
}

variable "ip_address_type" {
  description = "The type of IP address that should be used."
  type        = string
  default     = "Public" 
}

variable "os_type" {
  description = "The os type that should be used."
  type        = string
  default     = "Linux" 
}

variable "exposed_port" {
  description = "The port that should be exposed."
  type        = list(object({
    port     = number
    protocol = string
  }))
  default = []
}

variable "tags" {
  description = "Additional tags for container instances."
  type        = map(string)
  default     = {}
}

variable "containers" {
  description = "List of containers to be included in the container group"
  type = list(object({
    name   = string
    image  = string
    cpu    = string
    memory = string
    environment_variables = optional(map(string))
    ports  = object({
      port     = number
      protocol = string
    })
    liveness_probe      = optional(object({
      path                = string
      port                = number
      initial_delay_seconds = number
      period_seconds      = number
      success_threshold   = number
      failure_threshold   = number
    }))
    readiness_probe     = optional(object({
      path                = string
      port                = number
      initial_delay_seconds = number
      period_seconds      = number
      success_threshold   = number
      failure_threshold   = number
    }))
  }))
  default = []
}