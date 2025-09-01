# ACR Integration - Role Assignments and Configuration
# This file contains all ACR-related resources for the container apps job module
# Uses user-assigned managed identity authentication to avoid circular dependencies

# Create user-assigned managed identities for ACR integration
resource "azurerm_user_assigned_identity" "acr_identity" {
  for_each = var.acr_integration != null ? var.jobs : {}

  name                = "${each.value.name}-acr-identity"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  tags                = merge(var.tags, each.value.tags)
}

# Auto-assign ACR pull role to user-assigned managed identities
resource "azurerm_role_assignment" "acr_pull" {
  for_each = var.acr_integration != null ? var.jobs : {}

  scope                = var.acr_integration.registry_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.acr_identity[each.key].principal_id
}
