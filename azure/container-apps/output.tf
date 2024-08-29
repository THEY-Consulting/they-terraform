output "container_app_fqdn" {
  value = { for app in azurerm_container_app.container_app : app.name => app.latest_revision_fqdn }
}

