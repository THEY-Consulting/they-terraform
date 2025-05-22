variable "name" {
  description = "Name of the container registry."
  type        = string
}

variable "resource_group" {
  description = "The resource group where the registry will be created."
  type = object({
    name     = string
    location = string
  })
}

variable "sku" {
  description = "The SKU of the container registry. Possible values are 'Basic', 'Standard', and 'Premium'."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "The sku value must be one of 'Basic', 'Standard', or 'Premium'."
  }
}

variable "admin_enabled" {
  description = "Specifies whether the admin user is enabled."
  type        = bool
  default     = false
}

variable "retention_policy_days" {
  description = "The number of days to retain an untagged manifest after which it gets purged. Only available for Premium SKU."
  type        = number
  default     = 7
}

variable "quarantine_policy_enabled" {
  description = "Boolean value that indicates whether quarantine policy is enabled. Only available for Premium SKU."
  type        = bool
  default     = false
}

variable "trust_policy_enabled" {
  description = "Boolean value that indicates whether the trust policy is enabled. Only available for Premium SKU."
  type        = bool
  default     = false
}

variable "export_policy_enabled" {
  description = "Boolean value that indicates whether the export policy is enabled. Only available for Premium SKU."
  type        = bool
  default     = true
}

variable "anonymous_pull_enabled" {
  description = "Whether to allow anonymous (unauthenticated) pull access to this Container Registry. Only available for Standard and Premium SKUs."
  type        = bool
  default     = false
}

variable "data_endpoint_enabled" {
  description = "Whether to enable dedicated data endpoints for this Container Registry. Only available for Premium SKU."
  type        = bool
  default     = false
}

variable "network_rule_bypass_option" {
  description = "Whether to allow trusted Azure services to access a network restricted Container Registry."
  type        = string
  default     = "AzureServices"

  validation {
    condition     = contains(["None", "AzureServices"], var.network_rule_bypass_option)
    error_message = "The network_rule_bypass_option value must be one of 'None' or 'AzureServices'."
  }
}

variable "geo_replications" {
  description = "A list of Azure locations where the container registry should be geo-replicated. Only available for Premium SKU."
  type = list(object({
    location                  = string
    zone_redundancy_enabled   = optional(bool, false)
    regional_endpoint_enabled = optional(bool, false)
    tags                      = optional(map(string), {})
  }))
  default = []
}

variable "network_rule_set" {
  description = "Network rules for the container registry. Only available for Premium SKU."
  type = object({
    default_action = optional(string, "Allow")
    ip_rules       = optional(list(string), [])
  })
  default = null
}

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed for the container registry."
  type        = bool
  default     = true
}

variable "zone_redundancy_enabled" {
  description = "Whether zone redundancy is enabled for the container registry."
  type        = bool
  default     = false
}

variable "identity" {
  description = "The type of identity to use for the container registry."
  type = object({
    type         = string
    identity_ids = optional(list(string), null)
  })
  default = null
}

variable "encryption" {
  description = "Encryption settings for the container registry."
  type = object({
    key_vault_key_id   = string
    identity_client_id = string
  })
  default = null
}

variable "tags" {
  description = "Tags for the resources."
  type        = map(string)
  default     = {}
}
