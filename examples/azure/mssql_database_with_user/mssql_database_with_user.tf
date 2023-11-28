# --- RESOURCES / MODULES ---

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

module "mssql_database_with_user" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/database/mssql"
  source = "../../../azure/database/mssql"

  # database server names are blocked some time (approx. 1hr) after destroy, therefore use a random suffix to create unique names
  name                = "they-test-database-with-user-${random_string.suffix.id}"
  location            = "Germany West Central"
  resource_group_name = "they-dev"

  server = {
    administrator_login_password = sensitive("P@ssw0rd123!")
    allow_all                    = true
  }

  users = [
    {
      username = "they-test-user"
      password = sensitive("P@ssw0rd123!")
      roles    = ["db_owner"]
    }
  ]

  tags = {
    Project   = "they-terraform-examples"
    CreatedBy = "terraform"
  }
}

# --- OUTPUT ---

output "database_name" {
  value = module.mssql_database_with_user.database_name
}

output "server_domain_name" {
  value = module.mssql_database_with_user.server_domain_name
}

output "server_administrator_login" {
  value = module.mssql_database_with_user.server_administrator_login
}

output "ODBC_connection_string" {
  value = module.mssql_database_with_user.ODBC_connection_string
}

output "ADONET_connection_string" {
  value = module.mssql_database_with_user.ADONET_connection_string
}
