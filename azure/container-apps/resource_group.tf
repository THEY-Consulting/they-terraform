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
