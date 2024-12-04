locals {
  insights_tags = var.insights.enabled ? tomap({
    "hidden-link: /app-insights-resource-id" = replace(azurerm_application_insights.app_insights[0].id, "Microsoft.Insights", "microsoft.insights")
    # Note: below currently causes deployment problems with character limits
    #    "hidden-link: /app-insights-conn-string"         = azurerm_application_insights.app_insights[0].connection_string
    "hidden-link: /app-insights-instrumentation-key" = azurerm_application_insights.app_insights[0].instrumentation_key
  }) : {}
}

resource "azurerm_log_analytics_workspace" "analytics_workspace" {
  count = var.insights.enabled ? 1 : 0

  name                = "${var.name}-workspace"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.insights.sku
  retention_in_days   = var.insights.retention_in_days
}

resource "azurerm_application_insights" "app_insights" {
  count = var.insights.enabled ? 1 : 0

  name                = "${var.name}-app-insights"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.analytics_workspace.0.id
  application_type    = "web"

  # required to write and view logs in the azure portal
  internet_query_enabled     = true
  internet_ingestion_enabled = true
}
