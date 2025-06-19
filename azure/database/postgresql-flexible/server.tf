resource "azurerm_postgresql_flexible_server" "main" {
  name                   = var.server_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = var.postgres_version
  administrator_login    = var.admin_username
  administrator_password = var.admin_password

  sku_name          = var.sku_name
  storage_mb        = var.storage_mb
  storage_tier      = var.storage_tier
  auto_grow_enabled = var.auto_grow_enabled

  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []
    content {
      day_of_week  = maintenance_window.value.day_of_week
      start_hour   = maintenance_window.value.start_hour
      start_minute = maintenance_window.value.start_minute
    }
  }

  zone = var.zone
  dynamic "high_availability" {
    for_each = var.high_availability != null ? [var.high_availability] : []
    content {
      mode                      = high_availability.value.mode
      standby_availability_zone = high_availability.value.standby_availability_zone
    }
  }

  backup_retention_days = var.backup_retention_days

  public_network_access_enabled = var.enable_public_network_access

  lifecycle {
    ignore_changes = [
      zone,
      high_availability.0.standby_availability_zone,
    ]
  }
  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_configuration" "this" {
  for_each = { for cfg in var.pgsql_server_configurations : cfg.name => cfg }

  name      = each.value.name
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = each.value.value
}
