locals {
  location     = "North Europe" # Postgresql flexible in Germany West Central ist not available for our subscription
  project_name = "they-${terraform.workspace}-postgresql-flexible-server"
}

# CREATE RESOURCE GROUP in North Europe
resource "azurerm_resource_group" "this" {
  name     = local.project_name
  location = local.location
}


module "postgresql_flexible_server" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/database/postgresql-flexible"
  source = "../../../azure/database/postgresql-flexible"

  server_name         = local.project_name
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  admin_username      = "superAdmin"
  admin_password      = sensitive("P@ssw0rd123!")
  allow_all           = true
  #database_name       = "testdb" #If you want to create a database, uncomment this line.
  tags = {
    Environment = "${terraform.workspace}"
    ManagedBy   = "terraform"
  }

}

# OUTPUTS
output "server_fqdn" {
  value = module.postgresql_flexible_server.server_fqdn
}

output "connection_info" {
  value = module.postgresql_flexible_server.connection_info
}



