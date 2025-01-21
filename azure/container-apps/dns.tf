

data "azurerm_dns_zone" "main" {
  count               = var.dns_zone != null ? 1 : 0
  name                = var.dns_zone.existing_dns_zone_name
  resource_group_name = var.dns_zone.existing_dns_zone_resource_group_name
}

# https://learn.microsoft.com/en-us/azure/container-apps/custom-domains-managed-certificates?pivots=azure-portal
resource "azurerm_dns_txt_record" "main" {
  for_each            = var.dns_zone != null ? var.container_apps : {}
  name                = var.use_a_record == false ? "asuid.${each.value.subdomain}" : "asuid" # asuid. is azure specific and required as prefix
  resource_group_name = data.azurerm_dns_zone.main[0].resource_group_name
  zone_name           = data.azurerm_dns_zone.main[0].name
  ttl                 = var.ttl

  record {
    value = azurerm_container_app_environment.app_environment.custom_domain_verification_id
  }
}

resource "azurerm_dns_cname_record" "main" {
  for_each            = var.use_a_record == false ? var.container_apps : {}
  name                = each.value.subdomain
  resource_group_name = data.azurerm_dns_zone.main[0].resource_group_name
  zone_name           = data.azurerm_dns_zone.main[0].name
  ttl                 = var.ttl

  record = azurerm_container_app.container_app[each.key].ingress[0].fqdn
}

resource "azurerm_dns_a_record" "main" {
  for_each            = var.use_a_record == true ? var.container_apps : {}
  name                = "@" #each.value.subdomain
  zone_name           = data.azurerm_dns_zone.main[0].name
  resource_group_name = data.azurerm_dns_zone.main[0].resource_group_name
  ttl                 = var.ttl

  records = [azurerm_container_app_environment.app_environment.static_ip_address]
}

resource "azurerm_container_app_custom_domain" "main" {
  for_each         = var.dns_zone != null ? var.container_apps : {}
  name             = var.use_a_record == true ? "${var.dns_zone.existing_dns_zone_name}" : "${each.value.subdomain}.${var.dns_zone.existing_dns_zone_name}"
  container_app_id = azurerm_container_app.container_app[each.key].id
  container_app_environment_certificate_id = var.unique_environment_certificate != null ? azurerm_container_app_environment_certificate.app_environment_certificate[0].id : azurerm_container_app_environment_certificate.app_environment_certificate[
    index(keys(var.container_apps), each.key)
  ].id
  certificate_binding_type = var.certificate_binding_type

}
