resource "azurerm_container_app_environment" "app_environment" {
  name                       = var.name
  location                   = local.resource_group_location
  resource_group_name        = local.resource_group_name
  log_analytics_workspace_id = var.enable_log_analytics ? azurerm_log_analytics_workspace.log_analytics_workspace[0].id : null
  dynamic "workload_profile" {
    for_each = var.workload_profile != null ? [var.workload_profile] : []

    content {
      name                  = workload_profile.value.name
      workload_profile_type = workload_profile.value.workload_profile_type
    }
  }
}

resource "azurerm_container_app_environment_certificate" "app_environment_certificate" {
  for_each                     = var.container_apps
  name                         = "${each.value.name}-certificate"
  container_app_environment_id = azurerm_container_app_environment.app_environment.id
  certificate_blob_base64      = data.azurerm_key_vault_secret.secret[each.key].value
  certificate_password         = "" //TODO: add this as a variable. But for each container app or a general one?

  timeouts {
    delete = "10m"
  }
}

//workaround to assigne managed identity to container app environment: as of now, the azurerm_container_app_environment does not support managed identity
resource "null_resource" "assign_managed_identity" {
  provisioner "local-exec" {
    command = "az containerapp env identity assign --name ${azurerm_container_app_environment.app_environment.name} --resource-group ${local.resource_group_name} --system-assigned"
  }
  depends_on = [azurerm_container_app_environment.app_environment]
}
