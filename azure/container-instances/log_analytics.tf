resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  count               = var.enable_log_analytics ? 1 : 0
  name                = var.name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = var.sku_log_analytics
  retention_in_days   = var.log_retention
}

