variable "name" {
  description = "Name of project"
  type        = string
}

variable "create_new_resource_group" {
  description = "If true, a new resource group with the name `resource_group_name` that encompasses all resources will be created. Otherwise the deployment will use an existing resource group named `resource_group_name`."
  type        = bool
  default     = false
}

variable "resource_group_name" {
  description = "Name of resource group"
  type        = string
}

variable "log_retention" {
  description = "Amount of days for log retention"
  type        = number
  default     = 30
}

variable "location" {
  description = "The Azure region where the resources should be created."
  type        = string
}

// TODO: This variable can probably be removed. 
// First test with a deployment if there is no problem in removing
// this variable.
variable "container_registry_server" {
  description = "The server URL of the container registry."
  type        = string
  default     = null
}

variable "sku_log_analytics" {
  description = "The SKU of the log analytics workspace."
  type        = string
  default     = "PerGB2018"
}

variable "container_apps" {
  type = map(object({
    name                  = string
    tags                  = optional(map(string))
    revision_mode         = string
    workload_profile_name = optional(string)

    template = object({
      containers = set(object({
        name   = string
        image  = string
        cpu    = string
        memory = string
        env = optional(set(object({
          name        = string
          secret_name = optional(string)
          value       = optional(string)
        })))
      }))
      max_replicas = optional(number)
      min_replicas = optional(number)
    })

    ingress = optional(object({
      allow_insecure_connections = optional(bool, false)
      external_enabled           = optional(bool, false)
      ip_security_restrictions = optional(list(object({
        action           = string
        ip_address_range = string
        name             = string
        description      = optional(string)
      })), [])
      target_port = number
      traffic_weight = object({
        label           = optional(string)
        latest_revision = optional(string)
        revision_suffix = optional(string)
        percentage      = number
      })
      transport = optional(string)
    }))

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))

    secret = optional(object({
      name  = string
      value = string
    }))

    registry = optional(list(object({
      server               = string
      username             = optional(string)
      password_secret_name = optional(string)
      identity             = optional(string)
    })))
  }))
  description = "The container apps to deploy."
  nullable    = false
}
