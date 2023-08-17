terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }

  required_version = "1.5.5"
}

provider "azurerm" {
  features {}

  skip_provider_registration = true # We don't have enough permissions to register all providers
  tenant_id                  = var.tenant_id
}

variable "tenant_id" {
  description = "Use specific azure tenant ID."
  type        = string
  default     = null
}
