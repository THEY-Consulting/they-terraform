resource "azurerm_virtual_network" "main" {
  count = var.network.preexisting_name == null ? 1 : 0

  name                = "${var.name}-network"
  address_space       = var.network.address_space
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  tags = var.tags
}
data "azurerm_virtual_network" "main" {
  name                = coalesce(var.network.preexisting_name, azurerm_virtual_network.main.*.name...)
  resource_group_name = data.azurerm_resource_group.main.name
  depends_on          = [azurerm_virtual_network.main]
}

resource "azurerm_subnet" "internal" {
  name                 = var.name
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = data.azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_address_prefix]
}

resource "azurerm_route_table" "main" {
  name                = "${var.name}-routetable"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  dynamic "route" {
    for_each = var.routes
    content {
      name           = route.value.name
      address_prefix = route.value.address_prefix
      next_hop_type  = route.value.next_hop_type
    }
  }
}

resource "azurerm_subnet_route_table_association" "example" {
  subnet_id      = azurerm_subnet.internal.id
  route_table_id = azurerm_route_table.main.id
}

resource "azurerm_public_ip" "pip" {
  count = var.public_ip ? 1 : 0

  name                = "${var.name}-pip"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"

  tags = var.tags
}

resource "azurerm_network_interface" "main" {
  name                = "${var.name}-nic"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.public_ip ? azurerm_public_ip.pip[0].id : null
  }

  tags = var.tags
}
