# Only if the create_new_resource_group variable is set to true,
# a new resource group that emcompasses all newly created resources will be created. 
# Otherwise, terraform will try to find an existing resource group with the given name.

locals {
  resource_group_name     = var.create_new_resource_group ? azurerm_resource_group.resource_group[0].name : data.azurerm_resource_group.resource_group[0].name
  resource_group_location = var.create_new_resource_group ? azurerm_resource_group.resource_group[0].location : data.azurerm_resource_group.resource_group[0].location
}

resource "azurerm_resource_group" "resource_group" {
  count    = var.create_new_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
}

data "azurerm_resource_group" "resource_group" {
  count = var.create_new_resource_group ? 0 : 1
  name  = var.resource_group_name
}
