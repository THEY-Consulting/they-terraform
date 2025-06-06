resource "azurerm_postgresql_flexible_server_database" "main" {
  count     = var.database_name != null ? 1 : 0
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = var.collation
  charset   = var.charset

}
