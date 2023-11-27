# --- RESOURCES / MODULES ---

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

module "mssql_database_dtu" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/database/mssql"
  source = "../../../azure/database/mssql"

  # database server names are blocked some time (approx. 1hr) after destroy, therefore use a random suffix to create unique names
  name                = "they-test-database-dtu-${random_string.suffix.id}"
  location            = "Germany West Central"
  resource_group_name = "they-dev"

  server = {
    administrator_login_password = sensitive("P@ssw0rd123!")
    allow_all                    = true
  }

  sku_name                    = "Basic"
  min_capacity                = 0
  max_size_gb                 = 2
  auto_pause_delay_in_minutes = 0

  tags = {
    Project   = "they-terraform-examples"
    CreatedBy = "terraform"
  }
}

# --- OUTPUT ---

output "database_name" {
  value = module.mssql_database_dtu.database_name
}

output "server_domain_name" {
  value = module.mssql_database_dtu.server_domain_name
}

output "server_administrator_login" {
  value = module.mssql_database_dtu.server_administrator_login
}

output "ODBC_connection_string" {
  value = module.mssql_database_dtu.ODBC_connection_string
}
