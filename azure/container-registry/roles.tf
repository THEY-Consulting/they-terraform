# Role assignment for service principal access to the container registry
resource "azurerm_role_assignment" "service_principal_acr_access" {
  count                = var.service_principal_access != null ? 1 : 0
  scope                = azurerm_container_registry.acr.id
  role_definition_name = var.service_principal_access.role
  principal_id         = var.service_principal_access.principal_id
}
