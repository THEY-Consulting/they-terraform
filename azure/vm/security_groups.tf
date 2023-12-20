resource "azurerm_network_security_group" "main" {
  name                = "${var.name}-main"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  tags = var.tags
}

resource "azurerm_network_security_rule" "ssh" {
  count = var.allow_ssh ? 1 : 0

  name                        = "ssh"
  description                 = "Allow SSH from Internet"
  direction                   = "Inbound"
  access                      = "Allow"
  priority                    = 500
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_range      = "22"
  destination_address_prefix  = azurerm_network_interface.main.private_ip_address
  resource_group_name         = data.azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_network_security_rule" "rdp" {
  count = var.allow_rdp ? 1 : 0

  name                        = "rdp"
  description                 = "Allow RDP from Internet"
  direction                   = "Inbound"
  access                      = "Allow"
  priority                    = 550
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_range      = "3389"
  destination_address_prefix  = azurerm_network_interface.main.private_ip_address
  resource_group_name         = data.azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_network_security_rule" "rules" {
  count = length(var.security_rules)

  name                        = var.security_rules[count.index].name
  description                 = var.security_rules[count.index].description
  direction                   = var.security_rules[count.index].direction
  access                      = var.security_rules[count.index].access
  priority                    = var.security_rules[count.index].priority
  protocol                    = var.security_rules[count.index].protocol
  source_port_range           = var.security_rules[count.index].source_port_range
  source_address_prefix       = var.security_rules[count.index].source_address_prefix
  destination_port_range      = var.security_rules[count.index].destination_port_range
  destination_address_prefix  = azurerm_network_interface.main.private_ip_address
  resource_group_name         = data.azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_network_interface_security_group_association" "https" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}
