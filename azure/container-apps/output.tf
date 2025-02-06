locals {
  app_urls = { for app_name, app in var.container_apps : app_name =>
    var.dns_zone == null ? azurerm_container_app.container_app[app_name].latest_revision_fqdn : (
      var.use_a_record == true ? var.dns_zone.existing_dns_zone_name : "${app.subdomain}.${var.dns_zone.existing_dns_zone_name}"
    )
  }
}

output "container_apps_urls" {
  value = local.app_urls
}
# output "public_ip" {
# value = azurerm_container_app_environment.app_environment.static_ip_address
# }
