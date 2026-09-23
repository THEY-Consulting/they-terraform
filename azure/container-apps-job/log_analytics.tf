resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  count = local.create_log_analytics_workspace ? 1 : 0

  name                = coalesce(var.log_analytics_workspace_name, "${var.name}-log-analytics")
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  sku                 = var.sku_log_analytics
  retention_in_days   = var.log_retention
  tags                = var.tags
}
