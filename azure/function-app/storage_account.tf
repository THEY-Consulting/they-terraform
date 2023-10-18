resource "azurerm_storage_account" "managed_storage_account" {
  count = var.storage_account.name == null ? 0 : 1

  name                     = replace(var.name, "-", "")
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_account.tier
  account_replication_type = var.storage_account.replication_type
  min_tls_version          = var.storage_account.min_tls_version

  tags = var.tags
}

data "azurerm_storage_account" "storage_account" {
  name                = coalesce(var.storage_account.name, azurerm_storage_account.managed_storage_account.0.name)
  resource_group_name = var.resource_group_name
}
