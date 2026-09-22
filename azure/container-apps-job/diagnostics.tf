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
  namespace_resource_group_name     = var.diagnostics.namespace_resource_group_name
  enable_system_logs                = coalesce(var.diagnostics.enable_system_logs, false)
}
