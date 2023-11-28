# --- RESOURCES / MODULES ---

resource "azurerm_mssql_server" "existing" {
  name                         = "they-test-database-with-existing-server"
  location                     = "Germany West Central"
  resource_group_name          = "they-dev"
  version                      = "12.0"
  administrator_login          = "AdminUser"
  administrator_login_password = "P@ssw0rd123!"
  minimum_tls_version          = "1.2"

  tags = {
    Project   = "they-terraform-examples"
    CreatedBy = "terraform"
  }
}

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

module "mssql_database_with_existing_server" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/database/mssql"
  source = "../../../azure/database/mssql"

  # database server names are blocked some time (approx. 1hr) after destroy, therefore use a random suffix to create unique names
  name                = "they-test-database-with-existing-server-${random_string.suffix.id}"
  location            = "Germany West Central"
  resource_group_name = "they-dev"

  server = {
    preexisting_name = azurerm_mssql_server.existing.name
  }

  depends_on = [
    azurerm_mssql_server.existing
  ]
}

# --- OUTPUT ---

output "database_name" {
  value = module.mssql_database_with_existing_server.database_name
}

output "ODBC_connection_string" {
  value = module.mssql_database_with_existing_server.ODBC_connection_string
}

output "ADONET_connection_string" {
  value = module.mssql_database_with_existing_server.ADONET_connection_string
}
