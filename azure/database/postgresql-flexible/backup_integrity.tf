# ---------------------------------------------------------------------------
# Backup integrity check resources
# All resources are count-gated on var.enable_backup_integrity_check.
# ---------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "backup_integrity" {
  count = var.enable_backup_integrity_check ? 1 : 0
  name  = var.resource_group_name
}

resource "azurerm_automation_account" "backup_integrity" {
  count               = var.enable_backup_integrity_check ? 1 : 0
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

resource "azurerm_role_assignment" "automation_contributor" {
  count                = var.enable_backup_integrity_check ? 1 : 0
  scope                = data.azurerm_resource_group.backup_integrity[0].id
  role_definition_name = "Contributor"
  principal_id         = azurerm_automation_account.backup_integrity[0].identity[0].principal_id
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
    db_password         = var.admin_password
    db_user             = var.admin_username
    sanity_checks       = var.backup_integrity_checks
  })

  tags = var.tags
}

resource "azurerm_automation_schedule" "backup_integrity" {
  count                   = var.enable_backup_integrity_check ? 1 : 0
  name                    = "${var.server_name}-backup-integrity"
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.backup_integrity[0].name
  frequency               = var.backup_integrity_schedule.frequency
  interval                = var.backup_integrity_schedule.interval
  start_time              = timeadd(timestamp(), "24h")
  timezone                = var.backup_integrity_schedule.timezone

  lifecycle {
    ignore_changes = [start_time]
  }
}

resource "azurerm_automation_job_schedule" "backup_integrity" {
  count                   = var.enable_backup_integrity_check ? 1 : 0
  automation_account_name = azurerm_automation_account.backup_integrity[0].name
  resource_group_name     = var.resource_group_name
  runbook_name            = azurerm_automation_runbook.backup_integrity[0].name
  schedule_name           = azurerm_automation_schedule.backup_integrity[0].name
}
