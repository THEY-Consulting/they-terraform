locals {
  container_app_environment_id = var.container_app_environment_id != null ? var.container_app_environment_id : azurerm_container_app_environment.app_environment[0].id
}

data "azurerm_eventhub_namespace_authorization_rule" "main" {
  count = var.diagnostics == null ? 0 : 1

  name                = var.diagnostics.namespace_authorization_rule_name
  resource_group_name = var.diagnostics.namespace_resource_group_name != null ? var.diagnostics.namespace_resource_group_name : local.resource_group_name
  namespace_name      = var.diagnostics.namespace
}

resource "azurerm_monitor_diagnostic_setting" "container_app_environment" {
  count = var.diagnostics == null ? 0 : 1

  name                           = "container-app-environment-logs-to-event-hub"
  target_resource_id             = local.container_app_environment_id
  eventhub_authorization_rule_id = data.azurerm_eventhub_namespace_authorization_rule.main[0].id
  eventhub_name                  = var.diagnostics.eventhub

  enabled_log {
    category = "ContainerAppConsoleLogs"
  }

  enabled_log {
    category = "ContainerAppSystemLogs"
  }

  lifecycle {
    ignore_changes = [
      metric // prevents continuous diffs to the (unused by us) metric block
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "container_app_jobs" {
  for_each = var.diagnostics == null ? {} : var.jobs

  name                           = "container-app-job-${each.key}-logs-to-event-hub"
  target_resource_id             = azurerm_container_app_job.container_app_job[each.key].id
  eventhub_authorization_rule_id = data.azurerm_eventhub_namespace_authorization_rule.main[0].id
  eventhub_name                  = var.diagnostics.eventhub

  # Container App Jobs may not have specific log categories, but we need at least one block
  # Using category_group to capture all available logs
  enabled_log {
    category_group = "allLogs"
  }

  lifecycle {
    ignore_changes = [
      metric // prevents continuous diffs to the (unused by us) metric block
    ]
  }
}
