locals {
  resource_group_name     = var.resource_group_name != null ? data.azurerm_resource_group.resource_group[0].name : azurerm_resource_group.resource_group[0].name
  resource_group_location = var.resource_group_name != null ? data.azurerm_resource_group.resource_group[0].location : azurerm_resource_group.resource_group[0].location
}

resource "azurerm_resource_group" "resource_group" {
  count    = var.resource_group_name != null ? 0 : 1
  name     = var.name
  location = var.location
  tags     = var.tags
}

data "azurerm_resource_group" "resource_group" {
  count = var.resource_group_name != null ? 1 : 0
  name  = var.resource_group_name
}
