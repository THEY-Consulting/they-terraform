resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = var.name
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  sku                 = var.sku_log_analytics
}

