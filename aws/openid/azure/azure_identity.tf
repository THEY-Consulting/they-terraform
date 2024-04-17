resource "azurerm_user_assigned_identity" "managed_identity" {
  count = var.azure_identity_name == null ? 1 : 0

  location            = var.azure_location
  name                = "aws-token-provider-${var.name}"
  resource_group_name = var.azure_resource_group_name
}

data "azurerm_user_assigned_identity" "identity" {
  name                = coalesce(var.azure_identity_name, azurerm_user_assigned_identity.managed_identity.0.name)
  resource_group_name = var.azure_resource_group_name
}
