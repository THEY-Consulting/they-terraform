locals {
  # ACR names must be globally unique and only allow alphanumeric characters
  registry_name = "${terraform.workspace}registry${random_string.suffix.result}"

  tags = merge(var.tags, {
    Environment = terraform.workspace
  })
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Use existing resource group
data "azurerm_resource_group" "existing" {
  name = var.resource_group_name
}

# Container Registry
module "container_registry" {
  source = "../../../azure/container-registry"

  name = local.registry_name
  resource_group = {
    name     = data.azurerm_resource_group.existing.name
    location = data.azurerm_resource_group.existing.location
  }

  sku           = var.sku
  admin_enabled = true # Enable admin for simple authentication

  tags = local.tags
}
