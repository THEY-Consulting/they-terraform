
resource "azurerm_app_service_virtual_network_swift_connection" "app_connection" {
  count = var.needs_mdm_access ? 1 : 0

  app_service_id = local.function_app.id
  subnet_id      = azurerm_subnet.subnet.0.id
}

resource "azurerm_virtual_network" "vnet" {
  count = var.needs_mdm_access ? 1 : 0

  name                = "${local.name}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.1.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]
  tags                = var.tags
}

resource "azurerm_subnet" "subnet" {
  count = var.needs_mdm_access ? 1 : 0

  name                 = "${local.name}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.0.name
  address_prefixes     = ["10.1.0.0/24"]
  # service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "${local.name}-subnet-delegation"

    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
    }
  }
}

resource "azurerm_subnet_nat_gateway_association" "nat_gateway_association" {
  count = var.needs_mdm_access ? 1 : 0

  subnet_id      = azurerm_subnet.subnet.0.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.0.id
}

resource "azurerm_nat_gateway" "nat_gateway" {
  count = var.needs_mdm_access ? 1 : 0

  name                = "${local.name}-nat-gateway"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "ip_association" {
  count = var.needs_mdm_access ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.nat_gateway.0.id
  public_ip_address_id = azurerm_public_ip.public_ip.0.id
}

resource "azurerm_public_ip" "public_ip" {
  count = var.needs_mdm_access ? 1 : 0

  name                = "${local.name}-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1, 2, 3]
  tags                = var.tags
}

data "azurerm_network_security_group" "security_group" {
  name                = "MDM01-nsg"
  resource_group_name = "MDMProd"
}

locals {
  rule_name = "${local.name}-access-rule"
  rules     = data.azurerm_network_security_group.security_group.security_rule
}

resource "azurerm_network_security_rule" "mdm_origin_access" {
  count = var.needs_mdm_access ? 1 : 0

  network_security_group_name = data.azurerm_network_security_group.security_group.name
  resource_group_name         = data.azurerm_network_security_group.security_group.resource_group_name
  // use same prio if rule already exists or use highest prio + 1
  priority                   = contains(local.rules.*.name, local.rule_name) ? local.rules[index(local.rules.*.name, local.rule_name)].priority : min(local.rules.*.priority...) - 1
  source_address_prefix      = azurerm_public_ip.public_ip.0.ip_address
  name                       = "${local.name}-access-rule"
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "1433"
  destination_address_prefix = "*"
}
