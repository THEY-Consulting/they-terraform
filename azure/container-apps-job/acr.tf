# ACR Integration - Role Assignments and Configuration
# This file contains all ACR-related resources for the container apps job module
# Uses managed identity authentication only for security and simplicity

# Auto-assign ACR pull role to system-assigned managed identities
resource "azurerm_role_assignment" "acr_pull" {
  for_each = var.acr_integration != null ? var.jobs : {}

  scope                = var.acr_integration.registry_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_app_job.container_app_job[each.key].identity[0].principal_id

  depends_on = [azurerm_container_app_job.container_app_job]
}
