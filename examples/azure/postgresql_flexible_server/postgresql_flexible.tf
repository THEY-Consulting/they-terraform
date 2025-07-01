locals {
  location     = "North Europe" # Postgresql flexible in Germany West Central ist not available for our subscription
  project_name = "they-terraform-${terraform.workspace}-pgsql-flexible-example"
}


module "postgresql_flexible_server" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/database/postgresql-flexible"
  source = "../../../azure/database/postgresql-flexible"

  server_name         = local.project_name
  resource_group_name = "they-dev"
  location            = local.location
  admin_username      = "superAdmin"
  admin_password      = sensitive("P@ssw0rd123!")
  allow_all           = true
  #database_name       = "testdb" #If you want to create a database, uncomment this line.
  pgsql_server_configurations = [{
    name  = "azure.extensions",
    value = "UUID-OSSP,BTREE_GIST"
    }
  ]
  tags = {
    Environment = "${terraform.workspace}"
    ManagedBy   = "terraform"
  }

}

# OUTPUTS
output "server_fqdn" {
  value = module.postgresql_flexible_server.server_fqdn
}

output "db_connection_string" {
  value = module.postgresql_flexible_server.db_connection_string
}




