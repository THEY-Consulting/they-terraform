output "db_connection_string" {
  description = "Connection String that can be used to connect to the instance. If you use psql you could just run `psql 'connectionStringHere'` after replacing the password stub with the actual password"
  # https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING-URIS
  value = "postgres://${azurerm_postgresql_flexible_server.main.administrator_login}:ReplaceThisWithThePassword@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${var.database_name != null ? var.database_name : "postgres"}"
}

output "server_id" {
  description = "ID of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.id
}

output "server_fqdn" {
  description = "FQDN of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "admin_username" {
  description = "Administrator username"
  value       = azurerm_postgresql_flexible_server.main.administrator_login
}

output "backup_integrity_job_id" {
  description = "ID of the scheduled backup-integrity Container Apps Job, or null when disabled."
  value       = var.enable_backup_integrity_check ? module.backup_integrity_job[0].jobs["backup-integrity"].id : null
}

output "backup_integrity_log_analytics_workspace_id" {
  description = "Log Analytics workspace containing backup-integrity job logs, or null when disabled."
  value       = var.enable_backup_integrity_check ? module.backup_integrity_job[0].log_analytics_workspace_id : null
}

output "backup_integrity_failed_alert_id" {
  description = "Azure Monitor alert rule for failed backup-integrity checks, or null when disabled."
  value       = var.enable_backup_integrity_check ? azurerm_monitor_scheduled_query_rules_alert_v2.backup_integrity_failed[0].id : null
}
