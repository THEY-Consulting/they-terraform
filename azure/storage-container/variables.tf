variable "name" {
  description = "Name of the storage container."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the resources."
  type        = string
}

variable "location" {
  description = "The Azure region where the resources should be created."
  type        = string
}

variable "container_access_type" {
  description = "The access type for the container. Possible values are 'blob', 'container', or 'private'."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["blob", "container", "private"], var.container_access_type)
    error_message = "The container_access_type value must be one of 'blob', 'container', or 'private'."
  }
}

variable "metadata" {
  description = "A mapping of metadata to assign to the storage container."
  type        = map(string)
  default     = {}
}

variable "storage_account" {
  description = "The storage account configuration."
  type = object({
    preexisting_name                = optional(string, null)
    preexisting_resource_group_name = optional(string, null)
    name                            = optional(string, null)
    tier                            = optional(string, "Standard")
    replication_type                = optional(string, "LRS")
    kind                            = optional(string, "StorageV2")
    access_tier                     = optional(string, "Hot")
    is_hns_enabled                  = optional(bool, false)
    min_tls_version                 = optional(string, "TLS1_2")
    cors_rules = optional(list(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })), null)
  })
  default = {}
}

variable "tags" {
  description = "Tags for the resources."
  type        = map(string)
  default     = {}
}
