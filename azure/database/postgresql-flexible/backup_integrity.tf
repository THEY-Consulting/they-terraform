# ---------------------------------------------------------------------------
# Backup integrity check resources
# All resources are count-gated on var.enable_backup_integrity_check.
# ---------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "backup_integrity" {
  count = var.enable_backup_integrity_check ? 1 : 0
  name  = var.resource_group_name
}

locals {
  backup_integrity_schedule_now        = timestamp()
  backup_integrity_schedule_year       = tonumber(substr(local.backup_integrity_schedule_now, 0, 4))
  backup_integrity_schedule_month      = tonumber(substr(local.backup_integrity_schedule_now, 5, 2))
  backup_integrity_schedule_day        = tonumber(substr(local.backup_integrity_schedule_now, 8, 2))
  backup_integrity_schedule_next_month = local.backup_integrity_schedule_day >= var.backup_integrity_schedule.day_of_month

  backup_integrity_schedule_month_raw = local.backup_integrity_schedule_month + (
    local.backup_integrity_schedule_next_month ? 1 : 0
  )
  backup_integrity_schedule_bootstrap_year = local.backup_integrity_schedule_year + (
    local.backup_integrity_schedule_month_raw > 12 ? 1 : 0
  )
  backup_integrity_schedule_bootstrap_month = local.backup_integrity_schedule_month_raw > 12 ? 1 : local.backup_integrity_schedule_month_raw

  backup_integrity_schedule_computed_start_time = format(
    "%04d-%02d-%02dT00:00:00Z",
    local.backup_integrity_schedule_bootstrap_year,
    local.backup_integrity_schedule_bootstrap_month,
    var.backup_integrity_schedule.day_of_month,
  )
}

resource "terraform_data" "backup_integrity_schedule_bootstrap" {
  count = var.enable_backup_integrity_check ? 1 : 0

  input = local.backup_integrity_schedule_computed_start_time

  triggers_replace = {
    frequency    = var.backup_integrity_schedule.frequency
    interval     = tostring(var.backup_integrity_schedule.interval)
    day_of_month = tostring(var.backup_integrity_schedule.day_of_month)
  }

  lifecycle {
    ignore_changes = [input]
  }
}

resource "azurerm_automation_account" "backup_integrity" {
  count = var.enable_backup_integrity_check ? 1 : 0
  # Azure Automation Account names: 6–50 chars. PostgreSQL server names allow up to 63 chars,
  # so truncate to 39 chars before appending "-automation" (11 chars) → max 50 chars total.
  name                = "${substr(var.server_name, 0, 39)}-automation"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Basic"

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Custom role limited to the PostgreSQL Flexible Server operations the runbook
# actually needs: create/read/delete the restore server and write its firewall rule.
# This replaces the overly broad Contributor role.
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

resource "azurerm_role_assignment" "backup_integrity" {
  count              = var.enable_backup_integrity_check ? 1 : 0
  scope              = data.azurerm_resource_group.backup_integrity[0].id
  role_definition_id = azurerm_role_definition.backup_integrity[0].role_definition_resource_id
  principal_id       = azurerm_automation_account.backup_integrity[0].identity[0].principal_id
}

# Runtime Environment — creates a proper Python 3.10 sandbox.
# Packages are attached to the runtime environment, not the automation account directly.
# This is the correct modern approach; azurerm_automation_python3_package targets the legacy Python 3.8 runtime.
resource "azurerm_automation_runtime_environment" "python310" {
  count                 = var.enable_backup_integrity_check ? 1 : 0
  name                  = "python-3-10-backup-integrity"
  automation_account_id = azurerm_automation_account.backup_integrity[0].id
  runtime_language      = "Python"
  runtime_version       = "3.10"
  location              = var.location
  # Runtime Environment API enforces a max of 3 tags; omit here since the
  # automation account and runbook resources already carry the full tag set.
}

resource "azurerm_automation_runbook" "backup_integrity" {
  count                    = var.enable_backup_integrity_check ? 1 : 0
  name                     = "Test-BackupIntegrity"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  automation_account_name  = azurerm_automation_account.backup_integrity[0].name
  runbook_type             = "Python"
  runtime_environment_name = azurerm_automation_runtime_environment.python310[0].name
  log_progress             = true
  log_verbose              = false

  content = templatefile("${path.module}/runbooks/db_backup_integrity_check.py", {
    source_server_name  = var.server_name
    resource_group_name = var.resource_group_name
    subscription_id     = data.azurerm_client_config.current.subscription_id
    location            = var.location
    database_name       = coalesce(var.database_name, "postgres")
    db_password_var     = azurerm_automation_variable_string.db_password[0].name
    db_user             = var.admin_username
    sanity_checks       = var.backup_integrity_checks
  })

  tags = var.tags
}

# Store the DB password as an encrypted Automation variable so it is never
# baked into the runbook source or visible in the Azure portal's code view.
resource "azurerm_automation_variable_string" "db_password" {
  count                   = var.enable_backup_integrity_check ? 1 : 0
  name                    = "BackupIntegrityDbPassword"
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.backup_integrity[0].name
  value                   = var.admin_password
  encrypted               = true
}

resource "azurerm_automation_schedule" "backup_integrity" {
  count                   = var.enable_backup_integrity_check ? 1 : 0
  name                    = "${var.server_name}-backup-integrity"
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.backup_integrity[0].name
  frequency               = var.backup_integrity_schedule.frequency
  interval                = var.backup_integrity_schedule.interval
  month_days              = var.backup_integrity_schedule.frequency == "Month" ? [var.backup_integrity_schedule.day_of_month] : null
  start_time              = terraform_data.backup_integrity_schedule_bootstrap[0].output
  timezone                = "Etc/UTC"
}

resource "azurerm_automation_job_schedule" "backup_integrity" {
  count                   = var.enable_backup_integrity_check ? 1 : 0
  automation_account_name = azurerm_automation_account.backup_integrity[0].name
  resource_group_name     = var.resource_group_name
  runbook_name            = azurerm_automation_runbook.backup_integrity[0].name
  schedule_name           = azurerm_automation_schedule.backup_integrity[0].name
}
