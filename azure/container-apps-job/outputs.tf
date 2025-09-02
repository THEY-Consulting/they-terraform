output "jobs" {
  description = "Container app jobs with their basic information"
  value = {
    for job_name, job in azurerm_container_app_job.container_app_job : job_name => {
      id                           = job.id
      name                         = job.name
      resource_group_name          = job.resource_group_name
      container_app_environment_id = job.container_app_environment_id
    }
  }
}

output "container_app_environment_id" {
  description = "ID of the Container App Environment"
  value       = var.container_app_environment_id != null ? var.container_app_environment_id : azurerm_container_app_environment.app_environment[0].id
}

output "container_app_environment_name" {
  description = "Name of the Container App Environment"
  value       = var.container_app_environment_id != null ? data.azurerm_container_app_environment.existing[0].name : azurerm_container_app_environment.app_environment[0].name
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = local.resource_group_name
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace (if created)"
  value       = var.enable_log_analytics && var.diagnostics == null ? azurerm_log_analytics_workspace.log_analytics_workspace[0].id : null
}

output "shared_identity" {
  description = "Shared user-assigned managed identity for all jobs"
  value       = length(azurerm_user_assigned_identity.shared_identity) > 0 ? azurerm_user_assigned_identity.shared_identity[0] : null
}
