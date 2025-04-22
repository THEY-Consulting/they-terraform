variable "subscription_id" {
  description = "Use specific azure subscription ID."
  type        = string
}

variable "tenant_id" {
  description = "Use specific azure tenant ID."
  type        = string
  default     = null
}

variable "location" {
  description = "The Azure region where resources should be created."
  type        = string
  default     = "Germany West Central"
}

variable "resource_group_name" {
  description = "Name of the resource group where resources will be deployed."
  type        = string
  default     = "they-dev"
}

variable "sku" {
  description = "The SKU of the Container Registry."
  type        = string
  default     = "Standard"
}

variable "tags" {
  description = "Additional tags for all resources."
  type        = map(string)
  default     = {
    Project   = "Docker Registry"
    CreatedBy = "Terraform"
  }
}
