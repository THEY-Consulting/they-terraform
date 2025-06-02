module "domain" {
  source = "../frontdoor-domain"
  count  = var.is_external_dns_zone ? 0 : 1

  subdomain           = var.subdomain
  resource_group_name = coalesce(var.dns_zone_resource_group, var.resource_group.name)
  dns_zone_name       = var.dns_zone_name
  frontdoor_host_name = azurerm_cdn_frontdoor_endpoint.endpoint.host_name
  validation_token    = azurerm_cdn_frontdoor_custom_domain.custom_domain.validation_token
}
