# Create the DNS validation TXT record
resource "azurerm_dns_txt_record" "validation" {
  name                = "_dnsauth.${var.subdomain}"
  resource_group_name = var.resource_group_name
  zone_name           = var.dns_zone_name
  ttl                 = 3600

  record {
    value = var.validation_token # azurerm_cdn_frontdoor_custom_domain.custom_domain.validation_token
  }
}

resource "azurerm_dns_cname_record" "frontdoor" {
  name                = var.subdomain
  resource_group_name = var.resource_group_name
  zone_name           = var.dns_zone_name
  ttl                 = 3600
  record              = var.frontdoor_host_name # azurerm_cdn_frontdoor_endpoint.endpoint.host_name
}
