resource "azurerm_storage_account" "created_storage_account" {
  # TODO: perhaps add the containers we want to use here as optioanl variables
  # to have them automatically created
  count = var.storage_trigger.create_storage_account == true ? 1 : 0

  name                     = local.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  is_hns_enabled           = var.storage_account_options.is_hns_enabled
  account_tier             = var.storage_account_options.tier
  account_replication_type = var.storage_account_options.replication_type
  min_tls_version          = var.storage_account_options.min_tls_version

  tags = var.tags
}

# The storage account we are using
data "azurerm_storage_account" "main" {
  name                = local.storage_account_name
  resource_group_name = coalesce(var.storage_trigger.trigger_resource_group_name, var.resource_group_name)

  depends_on = [azurerm_storage_account.created_storage_account]
}

locals {
  # formats the name for the user based on azures requirements
  storage_account_name           = lower(replace(var.storage_trigger.trigger_storage_account_name, "-", ""))
  storage_account_resource_group = lower(replace(var.storage_trigger.trigger_storage_account_name, "-", ""))
}
