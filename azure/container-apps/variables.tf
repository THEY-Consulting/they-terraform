variable "name" {
  description = "Name of project, and of the resource group, when a new group is to be created."
  type        = string
}

variable "is_system_assigned" {
  description = "If true, a system-assigned managed identity will be created."
  type        = bool
  default     = false
}

variable "key_vault_name" {
  description = "Name of the key vault"
  type        = string
  default     = null
}

variable "unique_environment_certificate" {
  description = "Used to create a unique environment certificate. To create a certificate per container app, set this to null and specify the key_vault_secret_name in the container app configuration."
  type = object({
    name                  = string
    key_vault_secret_name = string
    password              = optional(string, "")
  })
  default = null
}

variable "key_vault_resource_group_name" {
  description = "Name of the resource group where the key vault is located"
  type        = string
  default     = null
}

variable "workload_profile" {
  type = object({
    name                  = string
    workload_profile_type = string // Possible values include Consumption, D4, D8, D16, D32, E4, E8, E16 and E32
    //https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment
  })
  default = null
}

variable "certificate_binding_type" {
  description = "value of the certificate binding type"
  type        = string
  default     = "SniEnabled"
}

variable "enable_log_analytics" {
  description = "If true, a log analytics workspace will be created."
  type        = bool
  default     = false

}

variable "resource_group_name" {
  description = "Name of resource group. Set this variable if you do not want to create a new resource group, but rather use an existing one."
  type        = string
  default     = null
}

variable "use_a_record" {
  description = "Boolean to determine if an A record should be created for the container app."
  type        = bool
  default     = false
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

variable "ttl" {
  description = "The TTL of the DNS record in seconds."
  type        = number
  default     = 300
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
    key_vault_secret_name = optional(string)
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
