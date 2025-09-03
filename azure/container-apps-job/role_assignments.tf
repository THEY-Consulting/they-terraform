# Role Assignments for Container App Jobs
# This file contains role assignment resources that grant Container App Jobs' managed identities
# access to Azure resources like Storage Accounts, Key Vaults, etc.

# Create a single shared user-assigned managed identity when ACR integration or role assignments are configured
resource "azurerm_user_assigned_identity" "shared_identity" {
  count = var.acr_integration != null || length(var.role_assignments) > 0 ? 1 : 0

  name                = "${var.name}-shared-identity"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  tags                = var.tags
}

# Each role assignment applies to all jobs since they share the same identity
resource "azurerm_role_assignment" "shared_identity" {
  for_each = {
    for assignment_idx, assignment in var.role_assignments : "${assignment.scope}-${assignment.role_definition_name}" => assignment
  }

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.shared_identity[0].principal_id

  depends_on = [azurerm_user_assigned_identity.shared_identity]
}

# Auto-assign ACR pull role to the shared identity when ACR integration is enabled
resource "azurerm_role_assignment" "acr_pull" {
  count = var.acr_integration != null ? 1 : 0

  scope                = var.acr_integration.registry_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.shared_identity[0].principal_id
}
