output "container_apps_urls" {
  value = var.dns_zone != null ? {
    for app_name, app in var.container_apps :
    app_name => "${app.subdomain}.${var.dns_zone.existing_dns_zone_name}"
  } : { for app in azurerm_container_app.container_app : app.name => app.latest_revision_fqdn }
}
