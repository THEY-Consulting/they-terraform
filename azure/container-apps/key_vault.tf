data "azurerm_key_vault" "key_vault" {
  count               = var.dns_zone != null ? 1 : 0
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group_name
}

data "azurerm_key_vault_secret" "secret" {
  count = var.dns_zone == null ? 0 : var.unique_environment_certificate != null ? 1 : length(var.container_apps)

  name         = var.unique_environment_certificate != null ? var.unique_environment_certificate.key_vault_secret_name : var.container_apps[keys(var.container_apps)[count.index]].key_vault_secret_name
  key_vault_id = var.dns_zone != null ? data.azurerm_key_vault.key_vault[0].id : null
}
