locals {
  location     = "North Europe" # Postgresql flexible in Germany West Central ist not available for our subscription
  project_name = "they-terraform-${terraform.workspace}-pgsql-flexible-example"
}


module "postgresql_flexible_server" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/database/postgresql-flexible"
  source = "../../../azure/database/postgresql-flexible"

  server_name           = local.project_name
  backup_integrity_name = substr("${local.project_name}-backup", 0, 28)
  resource_group_name   = "they-dev"
  location              = local.location
  admin_username        = "superAdmin"
  admin_password        = sensitive("P@ssw0rd123!")
  allow_all             = true
  #database_name       = "testdb" #If you want to create a database, uncomment this line.

  storage_mb        = 32768
  auto_grow_enabled = true

  pgsql_server_configurations = [{
    name  = "azure.extensions",
    value = "UUID-OSSP,BTREE_GIST"
    }
  ]
  tags = {
    Environment = terraform.workspace
    ManagedBy   = "terraform"
  }

  # ---------------------------------------------------------------------------
  # Optional: automated backup integrity check
  # Provisions a scheduled Azure Container Apps Job that runs a monthly PITR restore
  # and executes the queries below against the restored database.
  # Uncomment and adapt the checks to your schema to enable.
  # ---------------------------------------------------------------------------
  # enable_backup_integrity_check = true
  # database_name                 = "testdb"
  # backup_integrity_name         = "example-backup-integrity"
  # backup_integrity_container_image = "example.azurecr.io/postgresql-backup-integrity:2026.09.23"
  # backup_integrity_container_registry = {
  #   id           = "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.ContainerRegistry/registries/example"
  #   login_server = "example.azurecr.io"
  # }
  #
  # backup_integrity_checks = [
  #   {
  #     label = "users"
  #     query = "SELECT COUNT(*) FROM public.users"
  #   },
  #   {
  #     label       = "schema:public_exists"
  #     query       = "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name = 'public'"
  #     expect_rows = true
  #   },
  # ]
  #
  # # Optional — defaults to monthly / UTC.
  # # The module computes and freezes a future UTC-midnight bootstrap time automatically.
  # backup_integrity_schedule = {
  #   frequency   = "Month"
  #   interval    = 1
  #   day_of_month = 14
  #   # day_of_week = 1 # Monday, used when frequency = "Week"
  # }
  #
  # Optional — forward job console and system logs to the existing
  # environment-specific Event Hub (for example, the Datadog importer).
  # backup_integrity_diagnostics = {
  #   eventhub                          = "logs"
  #   namespace                         = "existing-eventhub-namespace"
  #   namespace_authorization_rule_name = "SendLogs"
  #   namespace_resource_group_name     = "they-dev"
  # }
}

# OUTPUTS
output "server_fqdn" {
  value = module.postgresql_flexible_server.server_fqdn
}

output "db_connection_string" {
  value = module.postgresql_flexible_server.db_connection_string
}
