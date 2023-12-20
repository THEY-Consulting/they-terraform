output "public_ip" {
  value = var.public_ip ? azurerm_public_ip.pip[0].ip_address : null
}

output "network_name" {
  value = data.azurerm_virtual_network.main.name
}

output "subnet_id" {
  value = azurerm_subnet.internal.id
}

output "network_security_group_id" {
  value = azurerm_network_security_group.main.id
}

output "vm_username" {
  value = var.vm_username
}
