resource "azurerm_container_app_environment" "app_environment" {
  name                       = var.name
  location                   = local.resource_group_location
  resource_group_name        = local.resource_group_name
  log_analytics_workspace_id = var.enable_log_analytics ? azurerm_log_analytics_workspace.log_analytics_workspace[0].id : null
  #TODO: add  workprofile attribute as a variable
}

resource "azurerm_container_app_environment_certificate" "app_environment_certificate" {
  name                         = var.environment_certificate_name
  container_app_environment_id = azurerm_container_app_environment.app_environment.id
  certificate_blob_base64      = data.azurerm_key_vault_secret.secret.value //sensitive(filebase64(var.environment_certificate_blob_path)) 
  certificate_password         = ""
}

//workaround to assigne managed identity to container app environment: as of now, the azurerm_container_app_environment does not support managed identity
resource "null_resource" "assign_managed_identity" {
  provisioner "local-exec" {
    command = "az containerapp env identity assign --name ${azurerm_container_app_environment.app_environment.name} --resource-group ${local.resource_group_name} --system-assigned"
  }
  depends_on = [azurerm_container_app_environment.app_environment]
}
