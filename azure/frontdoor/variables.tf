variable "resource_group" {
  description = "The resource group where the storage account will be created."
  type = object({
    name     = string
    location = string
  })
}

variable "storage_account" {
  description = "The storage account configuration."
}

variable "domain" {
  description = "The custom domain configuration."
  type        = string
}