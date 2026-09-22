output "id" {
  description = "ID of the managed-environment diagnostic setting."
  value       = azurerm_monitor_diagnostic_setting.container_app_environment.id
}
