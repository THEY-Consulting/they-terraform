resource "azurerm_mssql_firewall_rule" "azure_services" {
  count = (var.server.preexisting_name == null && var.server.allow_azure_resources) ? 1 : 0

  name      = "allow-azure-service"
  server_id = data.azurerm_mssql_server.main.id

  # allows access for azure resources
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_firewall_rule" "allow_all" {
  count = (var.server.preexisting_name == null && var.server.allow_all) ? 1 : 0

  name      = "allow-all"
  server_id = data.azurerm_mssql_server.main.id

  # allows access for all
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

resource "azurerm_mssql_firewall_rule" "firewall_rules" {
  count = var.server.preexisting_name == null ? length(var.server.firewall_rules) : 0

  name             = var.server.firewall_rules[count.index].name
  server_id        = data.azurerm_mssql_server.main.id
  start_ip_address = var.server.firewall_rules[count.index].start_ip_address
  end_ip_address   = var.server.firewall_rules[count.index].end_ip_address
}
