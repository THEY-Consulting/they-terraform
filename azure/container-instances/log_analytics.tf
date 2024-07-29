resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = var.name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "PerGB2018" # TODO: Check this field later!
  retention_in_days   = var.log_retention
}
