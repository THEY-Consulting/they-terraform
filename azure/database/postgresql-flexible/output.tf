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

output "connection_info" {
  description = "Connection information"
  value = {
    host     = azurerm_postgresql_flexible_server.main.fqdn
    port     = 5432
    username = azurerm_postgresql_flexible_server.main.administrator_login
    database = var.database_name != null ? var.database_name : "postgres"
  }
}
