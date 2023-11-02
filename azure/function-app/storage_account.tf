resource "azurerm_storage_account" "managed_storage_account" {
  # when preexisting_name is null, create a new storage account
  count = var.storage_account.preexisting_name == null ? 1 : 0

  name                     = replace(var.name, "-", "")
  resource_group_name      = var.resource_group_name
  location                 = var.location
  is_hns_enabled           = var.storage_account.is_hns_enabled
  account_tier             = var.storage_account.tier
  account_replication_type = var.storage_account.replication_type
  min_tls_version          = var.storage_account.min_tls_version

  tags = var.tags
}

data "azurerm_storage_account" "storage_account" {
  name                = coalesce(var.storage_account.preexisting_name, azurerm_storage_account.managed_storage_account.0.name)
  resource_group_name = var.resource_group_name
}
