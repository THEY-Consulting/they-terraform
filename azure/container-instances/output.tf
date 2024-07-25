output "container_fqdn" { //this shouldnt be relevant for the actual app
  value = var.dns_zone_name != null ? azurerm_dns_a_record.dns_a_record[0].fqdn : azurerm_container_group.container_group.ip_address
}


