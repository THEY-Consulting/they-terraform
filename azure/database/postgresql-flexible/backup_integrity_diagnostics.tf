module "backup_integrity_diagnostics" {
  count  = var.enable_backup_integrity_check && var.backup_integrity_diagnostics != null ? 1 : 0
  source = "../../container-apps-diagnostics"

  container_app_environment_id      = azurerm_container_app_environment.backup_integrity[0].id
  eventhub                          = var.backup_integrity_diagnostics.eventhub
  namespace                         = var.backup_integrity_diagnostics.namespace
  namespace_authorization_rule_name = var.backup_integrity_diagnostics.namespace_authorization_rule_name
  namespace_resource_group_name     = var.backup_integrity_diagnostics.namespace_resource_group_name
  log_analytics_workspace_id        = azurerm_log_analytics_workspace.backup_integrity[0].id
  enable_system_logs                = coalesce(var.backup_integrity_diagnostics.enable_system_logs, true)
}
