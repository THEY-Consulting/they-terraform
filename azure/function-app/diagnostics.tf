data "azurerm_eventhub_namespace_authorization_rule" "main" {
  count = var.diagnostics == null ? 0 : 1

  name                = var.diagnostics.namespace_authorization_rule_name
  resource_group_name = var.resource_group_name
  namespace_name      = var.diagnostics.namespace
}

resource "azurerm_monitor_diagnostic_setting" "example" {
  count = var.diagnostics == null ? 0 : 1

  name                           = "function-application-logs-to-event-hub"
  target_resource_id             = local.function_app.id
  eventhub_authorization_rule_id = data.azurerm_eventhub_namespace_authorization_rule.main[0].id
  eventhub_name                  = var.diagnostics.eventhub

  enabled_log {
    category = "FunctionAppLogs"
  }

  lifecycle {
    ignore_changes = [
      metric // prevents continuous diffs to the (unused by us) metric block
    ]
  }
}
