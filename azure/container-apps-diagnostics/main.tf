locals {
  managed_environment_resource_group_name = split("/", var.container_app_environment_id)[4]
}

data "azurerm_eventhub_namespace_authorization_rule" "main" {
  name                = var.namespace_authorization_rule_name
  resource_group_name = coalesce(var.namespace_resource_group_name, local.managed_environment_resource_group_name)
  namespace_name      = var.namespace
}

resource "azurerm_monitor_diagnostic_setting" "container_app_environment" {
  name                           = var.name
  target_resource_id             = var.container_app_environment_id
  eventhub_authorization_rule_id = data.azurerm_eventhub_namespace_authorization_rule.main.id
  eventhub_name                  = var.eventhub
  log_analytics_workspace_id     = var.log_analytics_workspace_id

  enabled_log {
    category = "ContainerAppConsoleLogs"
  }

  dynamic "enabled_log" {
    for_each = var.enable_system_logs ? [1] : []
    content {
      category = "ContainerAppSystemLogs"
    }
  }

}
