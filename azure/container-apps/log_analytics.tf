resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  count               = var.enable_log_analytics ? 1 : 0
  name                = var.name
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  sku                 = var.sku_log_analytics
  retention_in_days   = var.log_retention
  tags                = var.tags
}

