resource "azurerm_mssql_database" "main" {
  name                        = var.name
  server_id                   = data.azurerm_mssql_server.main.id
  collation                   = var.collation
  sku_name                    = var.sku_name
  max_size_gb                 = var.max_size_gb
  min_capacity                = var.min_capacity
  storage_account_type        = var.storage_account_type
  auto_pause_delay_in_minutes = var.auto_pause_delay_in_minutes

  tags = var.tags
}
