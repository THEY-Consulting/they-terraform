locals {
  container_app_environment_id = var.container_app_environment_id != null ? var.container_app_environment_id : azurerm_container_app_environment.app_environment[0].id
}

module "diagnostics" {
  count  = var.diagnostics == null ? 0 : 1
  source = "../container-apps-diagnostics"

  container_app_environment_id      = local.container_app_environment_id
  eventhub                          = var.diagnostics.eventhub
  namespace                         = var.diagnostics.namespace
  namespace_authorization_rule_name = var.diagnostics.namespace_authorization_rule_name
  # Preserve the existing module contract: this fallback belongs to the job
  # caller, not necessarily to an externally supplied managed environment.
  namespace_resource_group_name = coalesce(var.diagnostics.namespace_resource_group_name, local.resource_group_name)
  enable_system_logs            = coalesce(var.diagnostics.enable_system_logs, false)
}

# Preserve the existing diagnostic setting during the extraction to the shared
# module. Without this, Terraform would destroy and recreate the same Azure
# diagnostic-setting name and briefly interrupt log forwarding.
moved {
  from = azurerm_monitor_diagnostic_setting.container_app_environment[0]
  to   = module.diagnostics[0].azurerm_monitor_diagnostic_setting.container_app_environment
}
