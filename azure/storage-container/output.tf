output "id" {
  description = "The ID of the storage container."
  value       = azurerm_storage_container.container.id
}

output "name" {
  description = "The name of the storage container."
  value       = azurerm_storage_container.container.name
}

output "storage_account_name" {
  description = "The name of the storage account."
  value       = local.storage_account_name
}

output "storage_account_id" {
  description = "The ID of the storage account."
  value       = local.storage_account_id
}

output "primary_access_key" {
  description = "The primary access key for the storage account."
  value       = var.storage_account.preexisting_name == null ? azurerm_storage_account.storage_account[0].primary_access_key : data.azurerm_storage_account.existing[0].primary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "The primary connection string for the storage account."
  value       = var.storage_account.preexisting_name == null ? azurerm_storage_account.storage_account[0].primary_connection_string : data.azurerm_storage_account.existing[0].primary_connection_string
  sensitive   = true
}

output "container_url" {
  description = "The URL of the storage container."
  value       = "https://${local.storage_account_name}.blob.core.windows.net/${var.name}"
}
