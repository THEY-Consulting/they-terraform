locals {
  url_mapping = {
    no_dns_zone = { for app in azurerm_container_app.container_app : app.name => app.latest_revision_fqdn }
    a_record    = { for app_name, app in var.container_apps : app_name => var.dns_zone.existing_dns_zone_name }
    cname       = { for app_name, app in var.container_apps : app_name => "${app.subdomain}.${var.dns_zone.existing_dns_zone_name}" }
  }

  url_type = var.dns_zone == null ? "no_dns_zone" : (var.use_a_record ? "a_record" : "cname")
}

output "container_apps_urls" {
  value = local.url_mapping[local.url_type]
}
# output "public_ip" {
# value = azurerm_container_app_environment.app_environment.static_ip_address
# }
