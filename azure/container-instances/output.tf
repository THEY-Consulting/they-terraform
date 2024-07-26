output "container_fqdn" { //NOTE: should we rename? gives FQDN or public IP of the container group
  value = var.dns_zone_name != null ? azurerm_dns_a_record.dns_a_record[0].fqdn : azurerm_container_group.container_group.ip_address
}


