output "backend_fqdn" { //this shouldnt be relevant for the actual app
  value = azurerm_container_app.backend.latest_revision_fqdn
}

output "frontend_fqdn" {
  value = azurerm_container_app.frontend.latest_revision_fqdn
}

