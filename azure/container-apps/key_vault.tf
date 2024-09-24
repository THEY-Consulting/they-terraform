data "azurerm_key_vault" "key_vault" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group_name
}

data "azurerm_key_vault_secret" "secret" {
  count = var.unique_environment_certificate != null ? 1 : length(var.container_apps)

  name         = var.unique_environment_certificate != null ? var.unique_environment_certificate.key_vault_secret_name : var.container_apps[keys(var.container_apps)[count.index]].key_vault_secret_name
  key_vault_id = data.azurerm_key_vault.key_vault.id
}
