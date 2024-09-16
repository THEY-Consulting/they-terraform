variable "name" {
  description = "Name of project"
  type        = string
}

variable "create_new_resource_group" {
  description = "If true, a new resource group with the name `resource_group_name` that encompasses all resources will be created. Otherwise the deployment will use an existing resource group named `resource_group_name`."
  type        = bool
  default     = false
}

variable "key_vault_name" {
  description = "Name of the key vault"
  type        = string
}

variable "key_vault_resource_group_name" {
  description = "Name of the resource group where the key vault is located"
  type        = string
  default     = null
}

variable "key_vault_secret_name" {
  description = "Name of the key vault secret"
  type        = string

}

variable "environment_certificate_name" {
  description = "value of the environment certificate name"
  type        = string
}

variable "environment_certificate_blob_path" {
  description = "value of the environment certificate blob path"
  type        = string
  default     = null
}

variable "enable_log_analytics" {
  description = "If true, a log analytics workspace will be created."
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

variable "dns_zone" {
  description = "DNS zone config required if you want to link the deployed app to a subdomain in the given dns zone. Does not create a dns zone, only a subdomain."
  type = object({
    existing_dns_zone_name                = string
    existing_dns_zone_resource_group_name = string
  })
  default = null
}

variable "sku_log_analytics" {
  description = "The SKU of the log analytics workspace."
  type        = string
  default     = "PerGB2018"
}

variable "container_apps" {
  type = map(object({
    name                  = string
    subdomain             = optional(string) # only specify the subdomain part here. E.g. "test" for the dns zone "example.com" would result in test.example.com
    tags                  = optional(map(string))
    revision_mode         = string
    workload_profile_name = optional(string)
    cors_enabled          = optional(bool, false)
    cors_allowed_origins  = optional(string) //TODO: maybe make this a list?

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
      #TODO: do we need the key_vault attributes here? 
      # see https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app#secret
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