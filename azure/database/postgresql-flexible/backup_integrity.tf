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
  backup_integrity_reference_time = timeadd(timestamp(), "10m")
  backup_integrity_reference_date = substr(local.backup_integrity_reference_time, 0, 10)
  backup_integrity_weekday_numbers = {
    Mon = 1
    Tue = 2
    Wed = 3
    Thu = 4
    Fri = 5
    Sat = 6
    Sun = 7
  }
  backup_integrity_reference_weekday = local.backup_integrity_weekday_numbers[formatdate("EEE", local.backup_integrity_reference_time)]
  backup_integrity_week_offset_raw   = var.backup_integrity_schedule.day_of_week - local.backup_integrity_reference_weekday
  backup_integrity_week_offset       = local.backup_integrity_week_offset_raw > 0 ? local.backup_integrity_week_offset_raw : local.backup_integrity_week_offset_raw + 7
  backup_integrity_next_weekly = formatdate(
    "YYYY-MM-DD'T'00:00:00Z",
    timeadd("${local.backup_integrity_reference_date}T00:00:00Z", format("%dh", local.backup_integrity_week_offset * 24)),
  )
  backup_integrity_year       = tonumber(substr(local.backup_integrity_reference_time, 0, 4))
  backup_integrity_month      = tonumber(substr(local.backup_integrity_reference_time, 5, 2))
  backup_integrity_day        = tonumber(substr(local.backup_integrity_reference_time, 8, 2))
  backup_integrity_next_month = local.backup_integrity_day >= var.backup_integrity_schedule.day_of_month
  backup_integrity_month_raw  = local.backup_integrity_month + (local.backup_integrity_next_month ? 1 : 0)
  backup_integrity_anchor_year = local.backup_integrity_year + (
    local.backup_integrity_month_raw > 12 ? 1 : 0
  )
  backup_integrity_anchor_month = local.backup_integrity_month_raw > 12 ? 1 : local.backup_integrity_month_raw
  backup_integrity_schedule_anchor = var.backup_integrity_schedule.frequency == "Month" ? format(
    "%04d-%02d-%02dT00:00:00Z",
    local.backup_integrity_anchor_year,
    local.backup_integrity_anchor_month,
    var.backup_integrity_schedule.day_of_month,
    ) : var.backup_integrity_schedule.frequency == "Week" ? local.backup_integrity_next_weekly : formatdate(
    "YYYY-MM-DD'T'00:00:00Z",
    timeadd("${local.backup_integrity_reference_date}T00:00:00Z", "24h"),
  )
  # Container Apps cron uses five UTC fields. Cron cannot express elapsed
  # day/week/month intervals consistently, so it provides the base cadence and
  # the container applies the interval against the stable Terraform anchor.
  backup_integrity_cron = var.backup_integrity_schedule.frequency == "Month" ? "0 0 ${var.backup_integrity_schedule.day_of_month} * *" : var.backup_integrity_schedule.frequency == "Week" ? "0 0 * * ${local.backup_integrity_weekdays[var.backup_integrity_schedule.day_of_week]}" : "0 0 * * *"
}

# Retain the schedule anchor across applies. This resource deliberately keeps
# its first value, including when migrating an existing Automation schedule.
resource "terraform_data" "backup_integrity_schedule_bootstrap" {
  count = var.enable_backup_integrity_check ? 1 : 0

  input = local.backup_integrity_schedule_anchor

  triggers_replace = {
    frequency    = var.backup_integrity_schedule.frequency
    interval     = tostring(var.backup_integrity_schedule.interval)
    day_of_month = var.backup_integrity_schedule.frequency == "Month" ? tostring(var.backup_integrity_schedule.day_of_month) : ""
    day_of_week  = var.backup_integrity_schedule.frequency == "Week" ? tostring(var.backup_integrity_schedule.day_of_week) : ""
  }

  lifecycle {
    ignore_changes = [input]
  }
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
  log_analytics_workspace_id = var.backup_integrity_diagnostics == null ? azurerm_log_analytics_workspace.backup_integrity[0].id : null
  logs_destination           = var.backup_integrity_diagnostics != null ? "azure-monitor" : "log-analytics"
  tags                       = var.tags
}

resource "azurerm_key_vault" "backup_integrity" {
  count                      = var.enable_backup_integrity_check ? 1 : 0
  name                       = local.backup_integrity_key_vault_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  tags                       = var.tags
}

# The Terraform caller writes the secret once. This requires the deployment
# principal to have permission to create role assignments at Key Vault scope.
resource "azurerm_role_assignment" "backup_integrity_key_vault_deployer" {
  count                = var.enable_backup_integrity_check ? 1 : 0
  scope                = azurerm_key_vault.backup_integrity[0].id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# This has no additional state exposure: admin_password is already stored for
# the PostgreSQL server, as it was for the former encrypted Automation variable.
resource "azurerm_key_vault_secret" "backup_integrity_db_password" {
  count        = var.enable_backup_integrity_check ? 1 : 0
  name         = "backup-integrity-db-password"
  value        = var.admin_password
  key_vault_id = azurerm_key_vault.backup_integrity[0].id

  depends_on = [azurerm_role_assignment.backup_integrity_key_vault_deployer]
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

# A system-assigned identity does not exist until the job is created. A separate
# identity lets AcrPull be assigned before the job's first image pull, while the
# job's system-assigned identity remains responsible for PostgreSQL and Key Vault.
resource "azurerm_user_assigned_identity" "backup_integrity_acr_pull" {
  count               = var.enable_backup_integrity_check && var.backup_integrity_container_registry != null ? 1 : 0
  name                = "${local.backup_integrity_name}-acr-pull"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_role_assignment" "backup_integrity_acr_pull" {
  count                = var.enable_backup_integrity_check && var.backup_integrity_container_registry != null ? 1 : 0
  scope                = var.backup_integrity_container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.backup_integrity_acr_pull[0].principal_id
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

  identity {
    type         = var.backup_integrity_container_registry != null ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = var.backup_integrity_container_registry != null ? [azurerm_user_assigned_identity.backup_integrity_acr_pull[0].id] : null
  }
  schedule_trigger_config {
    cron_expression          = local.backup_integrity_cron
    parallelism              = 1
    replica_completion_count = 1
  }
  secret {
    name                = "db-password"
    key_vault_secret_id = azurerm_key_vault_secret.backup_integrity_db_password[0].versionless_id
    identity            = "System"
  }
  dynamic "registry" {
    for_each = var.backup_integrity_container_registry != null ? [var.backup_integrity_container_registry] : []
    content {
      server   = registry.value.login_server
      identity = azurerm_user_assigned_identity.backup_integrity_acr_pull[0].id
    }
  }
  template {
    container {
      name   = "backup-integrity"
      image  = coalesce(var.backup_integrity_container_image, "invalid.invalid/backup-integrity:missing")
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
        name  = "SCHEDULE_ANCHOR_DATE"
        value = substr(terraform_data.backup_integrity_schedule_bootstrap[0].output, 0, 10)
      }
      env {
        name  = "BACKUP_INTEGRITY_FORCE_RUN"
        value = tostring(var.backup_integrity_force_run)
      }
      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.backup_integrity_container_image != null && var.backup_integrity_container_registry != null
      error_message = "Set backup_integrity_container_image and backup_integrity_container_registry when enable_backup_integrity_check is true."
    }
  }

  depends_on = [azurerm_role_assignment.backup_integrity_acr_pull]
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
    query                   = "ContainerAppConsoleLogs | where JobName == '${local.backup_integrity_name}' | where Log contains 'Backup integrity check FAILED'"
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
