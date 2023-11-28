resource "azurerm_mssql_server" "managed" {
  count = var.server.preexisting_name == null ? 1 : 0

  name                         = var.name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = var.server.version
  administrator_login          = var.server.administrator_login
  administrator_login_password = var.server.administrator_login_password
  minimum_tls_version          = "1.2"

  tags = var.tags
}

data "azurerm_mssql_server" "main" {
  name                = coalesce(var.server.preexisting_name, azurerm_mssql_server.managed.*.name...)
  resource_group_name = var.resource_group_name
}
