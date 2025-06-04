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

  tags = var.tags
}

resource "azurerm_container_app_environment_certificate" "app_environment_certificate" {
  count = var.dns_zone == null ? 0 : length(local.certificate_names)

  name = local.certificate_names[count.index]

  container_app_environment_id = azurerm_container_app_environment.app_environment.id

  certificate_blob_base64 = data.azurerm_key_vault_secret.secret[var.unique_environment_certificate != null ? 0 : count.index].value

  certificate_password = var.unique_environment_certificate != null ? var.unique_environment_certificate.password : ""

  tags = var.tags
}

resource "null_resource" "assign_managed_identity" {
  count = var.is_system_assigned ? 1 : 0

  provisioner "local-exec" {
    command = "az containerapp env identity assign --name ${azurerm_container_app_environment.app_environment.name} --resource-group ${local.resource_group_name} --system-assigned"
  }

  depends_on = [azurerm_container_app_environment.app_environment]
}
