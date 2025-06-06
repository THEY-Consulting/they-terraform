locals {
  function_app = var.runtime.os == "windows" ? azurerm_windows_function_app.function_app[0] : azurerm_linux_function_app.function_app[0]
  name         = var.runtime.os == "windows" ? "${var.name}-windows-function-app" : "${var.name}-linux-function-app"
}

variable "name" {
  description = "Name of the function app."
  type        = string
}

variable "runtime" {
  description = "The runtime."
  type = object({
    name    = string
    version = string
    os      = optional(string, "windows")
  })
  default = {
    name    = "node"
    version = "~20"
    os      = "windows"
  }

  validation {
    condition     = var.runtime.name != "python" || var.runtime.os != "windows"
    error_message = "Python is not supported on Windows."
  }
}

variable "source_dir" {
  description = "Directory containing the function code."
  type        = string
}

variable "location" {
  description = "The Azure region where the resources should be created."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the function app."
  type        = string
}

variable "storage_account" {
  description = "The storage account."
  type = object({
    preexisting_name            = optional(string, null)
    preexisting_ressource_group = optional(string, null)
    is_hns_enabled              = optional(bool, false)
    tier                        = optional(string, "Standard")
    replication_type            = optional(string, "RAGRS") # Read-access geo-redundant storage (RA-GRS)
    min_tls_version             = optional(string, "TLS1_2")
  })
  default = {}
}

variable "service_plan" {
  description = "The service plan."
  type = object({
    name     = optional(string, null)
    sku_name = optional(string, "Y1")
  })
  default = {}
}

variable "insights" {
  description = "Application insights."
  type = object({
    enabled           = optional(bool, true)
    sku               = optional(string, "PerGB2018")
    retention_in_days = optional(number, 30)
  })
  default = {}
}

variable "environment" {
  description = "Map of environment variables that are accessible from the function code during execution."
  type        = map(string)
  default     = {}
}

variable "build" {
  description = "Build configuration."
  type = object({
    enabled   = optional(bool, true)
    command   = optional(string, "yarn run build")
    build_dir = optional(string, "dist")
  })
  default = {}
}

variable "is_bundle" {
  description = "If true, node_modules and .yarn directories will be excluded from the archive."
  default     = false
}

variable "archive" {
  description = "Archive configuration."
  type = object({
    output_path = optional(string, null)
    excludes    = optional(list(string), [])
  })
  default = {}
}

variable "storage_trigger" {
  description = "Storage trigger configuration."
  type = object({
    function_name                = string
    events                       = list(string)
    trigger_storage_account_name = optional(string) # defaults to the storage account of the function app
    trigger_resource_group_name  = optional(string) # defaults to the resource group of the function app
    subject_filter = optional(object({
      subject_begins_with = optional(string)
      subject_ends_with   = optional(string)
    }))
    retry_policy = optional(object({
      event_time_to_live    = optional(number, 360)
      max_delivery_attempts = optional(number, 1)
    }), { event_time_to_live = 360, max_delivery_attempts = 1 })
  })
  default = null
}

variable "identity" {
  description = "The identity."
  type = object({
    name = string
  })
  default = null
}

variable "assign_system_identity" {
  description = "If true, a system identity will be assigned to the function app."
  default     = false
}

variable "diagnostics" {
  description = "If set, function app logs will be sent to the event hub."
  type = object({
    eventhub                          = string
    namespace                         = string
    namespace_authorization_rule_name = string
  })
  default = null
}

variable "tags" {
  description = "Tags for the resources."
  type        = map(string)
  default     = {}
}
