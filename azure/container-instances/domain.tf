data "azurerm_dns_zone" "dns_zone" {
  count               = var.dns_zone_name != null ? 1 : 0
  name                = var.dns_zone_name
  resource_group_name = var.dns_resource_group
}

resource "azurerm_dns_a_record" "dns_a_record" {
  count               = var.dns_zone_name != null ? 1 : 0
  name                = var.dns_a_record_name
  zone_name           = data.azurerm_dns_zone.dns_zone[0].name
  resource_group_name = var.dns_resource_group
  ttl                 = var.dns_record_ttl
  records             = [azurerm_container_group.container_group.ip_address]
}
