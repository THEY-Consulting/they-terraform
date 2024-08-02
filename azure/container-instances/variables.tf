variable "name" {
  description = "Name of resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of resource group"
  type        = string
}

variable "create_new_resource_group" {
  description = "If true, a new resource group with the name `resource_group_name` that houses all resources will be created."
  type        = bool
  default     = false
}

variable "dns_resource_group" {
  description = "Resource group where the DNS zone is located."
  type        = string
  default     = null
}

variable "dns_a_record_name" {
  description = "The name of the DNS A record."
  type        = string
  default     = null
}

variable "dns_zone_name" {
  description = "The name of the DNS zone."
  type        = string
  default     = null
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

variable "enable_log_analytics" {
  description = "Enables the creation of the resource log analytics workspace for the container group."
  type        = bool
  default     = false
}

variable "sku_log_analytics" {
  description = "The SKU of the log analytics workspace."
  type        = string
  default     = "PerGB2018"
}

variable "log_retention" {
  description = "The number of days to retain logs in the log analytics workspace."
  type        = number
  default     = 30
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
  type = list(object({
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
    name                  = string
    image                 = string
    cpu                   = string
    memory                = string
    environment_variables = optional(map(string))
    ports = object({
      port     = number
      protocol = string
    })
    readiness_probe = optional(object({
      exec = optional(list(string))
      http_get = optional(object({
        path         = optional(string)
        port         = optional(number)
        scheme       = optional(string)
        http_headers = optional(map(string))
      }))
      initial_delay_seconds = optional(number)
      period_seconds        = optional(number)
      failure_threshold     = optional(number)
      success_threshold     = optional(number)
      timeout_seconds       = optional(number)
    }))

    liveness_probe = optional(object({
      exec = optional(list(string))
      http_get = optional(object({
        path         = optional(string)
        port         = optional(number)
        scheme       = optional(string)
        http_headers = optional(map(string))
      }))
      initial_delay_seconds = optional(number)
      period_seconds        = optional(number)
      failure_threshold     = optional(number)
      success_threshold     = optional(number)
      timeout_seconds       = optional(number)
    }))
  }))
  default = []
}

