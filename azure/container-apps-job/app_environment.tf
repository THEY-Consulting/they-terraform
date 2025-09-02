resource "azurerm_container_app_environment" "app_environment" {
  count = var.container_app_environment_id == null ? 1 : 0

  name                       = var.name
  location                   = local.resource_group_location
  resource_group_name        = local.resource_group_name
  log_analytics_workspace_id = var.enable_log_analytics ? azurerm_log_analytics_workspace.log_analytics_workspace[0].id : null
  infrastructure_subnet_id   = var.subnet_id
  logs_destination           = var.diagnostics != null ? "azure-monitor" : (var.enable_log_analytics ? "log-analytics" : "none")


  dynamic "workload_profile" {
    for_each = var.workload_profile != null ? [var.workload_profile] : []

    content {
      name                  = workload_profile.value.name
      workload_profile_type = workload_profile.value.workload_profile_type
    }
  }

  tags = var.tags
}

# Data source for existing environment if provided
data "azurerm_container_app_environment" "existing" {
  count = var.container_app_environment_id != null ? 1 : 0

  name                = split("/", var.container_app_environment_id)[8]
  resource_group_name = split("/", var.container_app_environment_id)[4]
}

# Assign system-assigned managed identity to the environment if requested
resource "null_resource" "assign_managed_identity" {
  count = var.is_system_assigned && var.container_app_environment_id == null ? 1 : 0

  provisioner "local-exec" {
    command = "az containerapp env identity assign --name ${azurerm_container_app_environment.app_environment[0].name} --resource-group ${local.resource_group_name} --system-assigned"
  }

  depends_on = [azurerm_container_app_environment.app_environment]
}
