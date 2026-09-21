# Scheduled Container Apps Job for PostgreSQL backup-integrity validation.
data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "backup_integrity" {
  count = var.enable_backup_integrity_check ? 1 : 0
  name  = var.resource_group_name
}

locals {
  backup_integrity_name           = substr("${var.server_name}-backup-integrity", 0, 32)
  backup_integrity_key_vault_name = lower("${substr(replace(var.server_name, "-", ""), 0, 15)}bkp${substr(md5("${data.azurerm_client_config.current.subscription_id}/${var.server_name}"), 0, 6)}")
  backup_integrity_weekdays       = { 1 = "MON", 2 = "TUE", 3 = "WED", 4 = "THU", 5 = "FRI", 6 = "SAT", 7 = "SUN" }
  # Container Apps cron uses five UTC fields. Weekly cron cannot express an
  # every-N-weeks cadence; interval > 1 is handled by the container itself.
  backup_integrity_cron = var.backup_integrity_schedule.frequency == "Month" ? "0 0 ${var.backup_integrity_schedule.day_of_month} */${var.backup_integrity_schedule.interval} *" : var.backup_integrity_schedule.frequency == "Week" ? "0 0 * * ${local.backup_integrity_weekdays[var.backup_integrity_schedule.day_of_week]}" : "0 0 */${var.backup_integrity_schedule.interval} * *"
}

resource "azurerm_log_analytics_workspace" "backup_integrity" {
  count               = var.enable_backup_integrity_check ? 1 : 0
  name                = "${local.backup_integrity_name}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.backup_integrity_log_retention_days
  tags                = var.tags
}

resource "azurerm_container_app_environment" "backup_integrity" {
  count                      = var.enable_backup_integrity_check ? 1 : 0
  name                       = "${local.backup_integrity_name}-env"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.backup_integrity[0].id
  logs_destination           = "log-analytics"
  tags                       = var.tags
}

resource "azurerm_key_vault" "backup_integrity" {
  count                      = var.enable_backup_integrity_check ? 1 : 0
  name                       = local.backup_integrity_key_vault_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  enable_rbac_authorization  = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  tags                       = var.tags
}

# This has no additional state exposure: admin_password is already stored for
# the PostgreSQL server, as it was for the former encrypted Automation variable.
resource "azurerm_key_vault_secret" "backup_integrity_db_password" {
  count        = var.enable_backup_integrity_check ? 1 : 0
  name         = "backup-integrity-db-password"
  value        = var.admin_password
  key_vault_id = azurerm_key_vault.backup_integrity[0].id
}

resource "azurerm_role_definition" "backup_integrity" {
  count = var.enable_backup_integrity_check ? 1 : 0
  name  = "${var.server_name}-backup-integrity"
  scope = data.azurerm_resource_group.backup_integrity[0].id
  permissions {
    actions = [
      "Microsoft.DBforPostgreSQL/flexibleServers/read",
      "Microsoft.DBforPostgreSQL/flexibleServers/write",
      "Microsoft.DBforPostgreSQL/flexibleServers/delete",
      "Microsoft.DBforPostgreSQL/flexibleServers/firewallRules/write",
    ]
    not_actions = []
  }
  assignable_scopes = [data.azurerm_resource_group.backup_integrity[0].id]
}

resource "azurerm_container_app_job" "backup_integrity" {
  count                        = var.enable_backup_integrity_check ? 1 : 0
  name                         = local.backup_integrity_name
  location                     = var.location
  resource_group_name          = var.resource_group_name
  container_app_environment_id = azurerm_container_app_environment.backup_integrity[0].id
  replica_timeout_in_seconds   = var.backup_integrity_replica_timeout_seconds
  replica_retry_limit          = var.backup_integrity_replica_retry_limit
  tags                         = var.tags

  identity { type = "SystemAssigned" }
  schedule_trigger_config {
    cron_expression          = local.backup_integrity_cron
    parallelism              = 1
    replica_completion_count = 1
  }
  secret {
    name                = "db-password"
    key_vault_secret_id = azurerm_key_vault_secret.backup_integrity_db_password[0].versionless_id
    identity            = "system"
  }
  template {
    container {
      name   = "backup-integrity"
      image  = var.backup_integrity_container_image
      cpu    = 0.5
      memory = "1Gi"
      env {
        name  = "SOURCE_SERVER_NAME"
        value = var.server_name
      }
      env {
        name  = "RESOURCE_GROUP_NAME"
        value = var.resource_group_name
      }
      env {
        name  = "SUBSCRIPTION_ID"
        value = data.azurerm_client_config.current.subscription_id
      }
      env {
        name  = "LOCATION"
        value = var.location
      }
      env {
        name  = "DATABASE_NAME"
        value = coalesce(var.database_name, "postgres")
      }
      env {
        name  = "DB_USER"
        value = var.admin_username
      }
      env {
        name  = "SANITY_CHECKS_JSON"
        value = jsonencode(var.backup_integrity_checks)
      }
      env {
        name  = "SCHEDULE_FREQUENCY"
        value = var.backup_integrity_schedule.frequency
      }
      env {
        name  = "SCHEDULE_INTERVAL"
        value = tostring(var.backup_integrity_schedule.interval)
      }
      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }
    }
  }
}

resource "azurerm_role_assignment" "backup_integrity" {
  count              = var.enable_backup_integrity_check ? 1 : 0
  scope              = data.azurerm_resource_group.backup_integrity[0].id
  role_definition_id = azurerm_role_definition.backup_integrity[0].role_definition_resource_id
  principal_id       = azurerm_container_app_job.backup_integrity[0].identity[0].principal_id
}

resource "azurerm_role_assignment" "backup_integrity_key_vault" {
  count                = var.enable_backup_integrity_check ? 1 : 0
  scope                = azurerm_key_vault.backup_integrity[0].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_container_app_job.backup_integrity[0].identity[0].principal_id
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "backup_integrity_failed" {
  count                = var.enable_backup_integrity_check ? 1 : 0
  name                 = "${local.backup_integrity_name}-failed"
  resource_group_name  = var.resource_group_name
  location             = var.location
  scopes               = [azurerm_log_analytics_workspace.backup_integrity[0].id]
  description          = "PostgreSQL backup integrity check failed."
  severity             = 2
  enabled              = true
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  criteria {
    query                   = "ContainerAppConsoleLogs_CL | where Log_s contains 'Backup integrity check FAILED' | where Log_s contains '${var.server_name}'"
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
  }
  dynamic "action" {
    for_each = length(var.backup_integrity_alert_action_group_ids) == 0 ? [] : [1]
    content {
      action_groups = var.backup_integrity_alert_action_group_ids
    }
  }
}
