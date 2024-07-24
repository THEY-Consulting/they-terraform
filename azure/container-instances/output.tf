output "frontend_fqdn" { //this shouldnt be relevant for the actual app
  value = azurerm_container_group.container_group.fqdn
}


