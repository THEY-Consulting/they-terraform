data "azurerm_dns_zone" "dns_zone" {
  name                = "they-azure.de"
}
resource "azurerm_dns_a_record" "example" {
  name                = "mso-test"
  zone_name           = "they-azure.de"
  resource_group_name = "they-dev"
  ttl                 = 300
  #target_resource_id  = azurerm_container_group.container_group.id
  records = [ azurerm_container_group.container_group.ip_address ]
}