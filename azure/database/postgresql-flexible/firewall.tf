resource "azurerm_postgresql_flexible_server_firewall_rule" "allowed_ips" {
  count            = length(var.allowed_ip_ranges)
  name             = var.allowed_ip_ranges[count.index].name
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = var.allowed_ip_ranges[count.index].start_ip_address
  end_ip_address   = var.allowed_ip_ranges[count.index].end_ip_address
}

# Allow Azure services access
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  count            = var.allow_azure_services ? 1 : 0
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Allow all IP addresses access
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_all" {
  count            = var.allow_all ? 1 : 0
  name             = "AllowAll"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}
