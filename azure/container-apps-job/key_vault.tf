data "azurerm_key_vault" "key_vault" {
  count = var.key_vault_name != null ? 1 : 0
  
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group_name != null ? var.key_vault_resource_group_name : local.resource_group_name
}
