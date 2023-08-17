data "azurerm_user_assigned_identity" "identity" {
  count = var.identity != null ? 1 : 0

  name                = var.identity.name
  resource_group_name = var.resource_group_name
}
