locals {
  storage_account_name = var.storage_account.preexisting_name != null ? var.storage_account.preexisting_name : azurerm_storage_account.storage_account[0].name
  storage_account_id   = var.storage_account.preexisting_name != null ? data.azurerm_storage_account.existing[0].id : azurerm_storage_account.storage_account[0].id
}

data "azurerm_storage_account" "existing" {
  count = var.storage_account.preexisting_name != null ? 1 : 0

  name                = var.storage_account.preexisting_name
  resource_group_name = var.storage_account.preexisting_resource_group_name != null ? var.storage_account.preexisting_resource_group_name : var.resource_group_name
}

resource "azurerm_storage_container" "container" {
  name                              = var.name
  storage_account_id                = local.storage_account_id
  container_access_type             = var.container_access_type
  metadata                          = var.metadata
}

resource "azurerm_storage_account" "storage_account" {
  count = var.storage_account.preexisting_name == null ? 1 : 0

  name                     = coalesce(var.storage_account.name, replace(var.name, "-", ""))
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_account.tier
  account_replication_type = var.storage_account.replication_type
  account_kind             = var.storage_account.kind
  access_tier              = var.storage_account.access_tier
  is_hns_enabled           = var.storage_account.is_hns_enabled
  min_tls_version          = var.storage_account.min_tls_version

  tags = var.tags
}

resource "azurerm_storage_account_static_website" "static_website" {
  count = var.storage_account.preexisting_name == null ? 1 : 0

  storage_account_id = azurerm_storage_account.storage_account[0].id
  #error_404_document = "customnotfound.html"
  index_document = "index.html"
}

