# Scheduled Container Apps Job for PostgreSQL backup-integrity validation.
data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "backup_integrity" {
  count = var.enable_backup_integrity_check ? 1 : 0
  name  = var.resource_group_name
}

locals {
  # This placeholder is used only to keep resource arguments type-valid until
  # the enabled-job precondition can report a missing explicit name.
  backup_integrity_resource_name  = coalesce(var.backup_integrity_name, "backup-integrity-missing")
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

resource "terraform_data" "backup_integrity_configuration" {
  count = var.enable_backup_integrity_check ? 1 : 0

  input = local.backup_integrity_resource_name

  lifecycle {
    precondition {
      condition     = var.backup_integrity_name != null && trimspace(var.backup_integrity_name) != "" && var.backup_integrity_container_image != null && var.backup_integrity_container_registry != null
      error_message = "Set backup_integrity_name, backup_integrity_container_image, and backup_integrity_container_registry when enable_backup_integrity_check is true."
    }
  }
}

# The shared module owns the Container Apps infrastructure. Backup-specific
# restore access, schedule anchoring, Key Vault secret, and alerting stay here.
module "backup_integrity_job" {
  count  = var.enable_backup_integrity_check ? 1 : 0
  source = "../../container-apps-job"

  name                                  = local.backup_integrity_resource_name
  location                              = var.location
  resource_group_name                   = var.resource_group_name
  container_app_environment_name        = "${local.backup_integrity_resource_name}-env"
  enable_log_analytics                  = true
  enable_log_analytics_with_diagnostics = true
  log_analytics_workspace_name          = "${local.backup_integrity_resource_name}-logs"
  log_retention                         = var.backup_integrity_log_retention_days
  tags                                  = var.tags
  acr_integration = var.backup_integrity_container_registry == null ? null : {
    registry_id   = var.backup_integrity_container_registry.id
    login_server  = var.backup_integrity_container_registry.login_server
    identity_name = "${local.backup_integrity_resource_name}-acr-pull"
  }
  diagnostics = var.backup_integrity_diagnostics == null ? null : {
    eventhub                          = var.backup_integrity_diagnostics.eventhub
    namespace                         = var.backup_integrity_diagnostics.namespace
    namespace_authorization_rule_name = var.backup_integrity_diagnostics.namespace_authorization_rule_name
    namespace_resource_group_name     = var.backup_integrity_diagnostics.namespace_resource_group_name
    enable_system_logs                = coalesce(var.backup_integrity_diagnostics.enable_system_logs, true)
  }
  secrets = [{
    name                = "db-password"
    key_vault_secret_id = azurerm_key_vault_secret.backup_integrity_db_password[0].versionless_id
    identity            = "System"
  }]
  jobs = {
    backup-integrity = {
      name                = local.backup_integrity_resource_name
      replica_timeout     = var.backup_integrity_replica_timeout_seconds
      replica_retry_limit = var.backup_integrity_replica_retry_limit
      inject_app_name     = false
      schedule_trigger_config = {
        cron_expression = local.backup_integrity_cron
      }
      identity = {
        type = "SystemAssigned, UserAssigned"
      }
      template = {
        containers = [{
          name   = "backup-integrity"
          image  = coalesce(var.backup_integrity_container_image, "invalid.invalid/backup-integrity:missing")
          cpu    = "0.5"
          memory = "1Gi"
          env = [
            { name = "SOURCE_SERVER_NAME", value = var.server_name },
            { name = "RESOURCE_GROUP_NAME", value = var.resource_group_name },
            { name = "SUBSCRIPTION_ID", value = data.azurerm_client_config.current.subscription_id },
            { name = "LOCATION", value = var.location },
            { name = "DATABASE_NAME", value = coalesce(var.database_name, "postgres") },
            { name = "DB_USER", value = var.admin_username },
            { name = "SANITY_CHECKS_JSON", value = jsonencode(var.backup_integrity_checks) },
            { name = "SCHEDULE_FREQUENCY", value = var.backup_integrity_schedule.frequency },
            { name = "SCHEDULE_INTERVAL", value = tostring(var.backup_integrity_schedule.interval) },
            { name = "SCHEDULE_ANCHOR_DATE", value = substr(terraform_data.backup_integrity_schedule_bootstrap[0].output, 0, 10) },
            { name = "BACKUP_INTEGRITY_FORCE_RUN", value = tostring(var.backup_integrity_force_run) },
            { name = "DB_PASSWORD", secret_name = "db-password" },
          ]
        }]
      }
    }
  }

  depends_on = [terraform_data.backup_integrity_configuration]
}

resource "azurerm_role_assignment" "backup_integrity" {
  count              = var.enable_backup_integrity_check ? 1 : 0
  scope              = data.azurerm_resource_group.backup_integrity[0].id
  role_definition_id = azurerm_role_definition.backup_integrity[0].role_definition_resource_id
  principal_id       = module.backup_integrity_job[0].jobs["backup-integrity"].principal_id
}

resource "azurerm_role_assignment" "backup_integrity_key_vault" {
  count                = var.enable_backup_integrity_check ? 1 : 0
  scope                = azurerm_key_vault.backup_integrity[0].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.backup_integrity_job[0].jobs["backup-integrity"].principal_id
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "backup_integrity_failed" {
  count                = var.enable_backup_integrity_check ? 1 : 0
  name                 = "${local.backup_integrity_resource_name}-failed"
  resource_group_name  = var.resource_group_name
  location             = var.location
  scopes               = [module.backup_integrity_job[0].log_analytics_workspace_id]
  description          = "PostgreSQL backup integrity check failed."
  severity             = 2
  enabled              = true
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  criteria {
    query                   = "ContainerAppConsoleLogs | where JobName == '${local.backup_integrity_resource_name}' | where Log contains 'Backup integrity check FAILED'"
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

# Preserve deployed backup-integrity infrastructure while moving it behind the
# reusable Container Apps Job module.
moved {
  from = azurerm_log_analytics_workspace.backup_integrity[0]
  to   = module.backup_integrity_job[0].azurerm_log_analytics_workspace.log_analytics_workspace[0]
}

moved {
  from = azurerm_container_app_environment.backup_integrity[0]
  to   = module.backup_integrity_job[0].azurerm_container_app_environment.app_environment[0]
}

moved {
  from = azurerm_user_assigned_identity.backup_integrity_acr_pull[0]
  to   = module.backup_integrity_job[0].azurerm_user_assigned_identity.shared_identity[0]
}

moved {
  from = azurerm_role_assignment.backup_integrity_acr_pull[0]
  to   = module.backup_integrity_job[0].azurerm_role_assignment.acr_pull[0]
}

moved {
  from = azurerm_container_app_job.backup_integrity[0]
  to   = module.backup_integrity_job[0].azurerm_container_app_job.container_app_job["backup-integrity"]
}

moved {
  from = module.backup_integrity_diagnostics[0].azurerm_monitor_diagnostic_setting.container_app_environment
  to   = module.backup_integrity_job[0].module.diagnostics[0].azurerm_monitor_diagnostic_setting.container_app_environment
}
