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
  tags                     = var.tags

  dynamic "network_rules" {
    for_each = var.needs_mdm_access ? [true] : []

    content {
      default_action             = "Deny"
      virtual_network_subnet_ids = [azurerm_subnet.subnet.id]
    }
  }
}

data "azurerm_storage_account" "storage_account" {
  name                = var.storage_account.preexisting_name != null ? var.storage_account.preexisting_name : azurerm_storage_account.managed_storage_account.0.name
  resource_group_name = var.storage_account.preexisting_ressource_group != null ? var.storage_account.preexisting_ressource_group : var.resource_group_name
}
