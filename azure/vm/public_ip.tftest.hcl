# Run with Terraform >= 1.7. All Azure operations are mocked.
mock_provider "azurerm" {
  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-network/subnets/test-vm"
    }
  }

  mock_resource "azurerm_route_table" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/routeTables/test-route-table"
    }
  }

  mock_resource "azurerm_network_interface" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkInterfaces/test-nic"
    }
  }

  mock_resource "azurerm_network_security_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkSecurityGroups/test-nsg"
    }
  }

  mock_resource "azurerm_linux_virtual_machine" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Compute/virtualMachines/test-vm"
    }
  }

  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-workspace"
    }
  }

  mock_data "azurerm_resource_group" {
    defaults = {
      location = "germanywestcentral"
    }
  }

  mock_resource "azurerm_public_ip" {
    defaults = {
      id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/publicIPAddresses/test-vm-pip"
      ip_address = "192.0.2.10"
    }
  }
}

variables {
  name                = "test-vm"
  resource_group_name = "test-rg"
  vm_password         = "Test-fixture-only-123!"
  vm_public_ssh_key   = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD/NicVcIfvvwKdu1Z2IozxJwlAIhndwVwlvKYXhCGIjl37aHvNfJdWXX4IxjfyGHvNN9Q/no/SED63H4/6O7ITBn6do6jcvx+c6OEwX0Qa1VwwlVPxmttUzItA65rzAoQK2GfccscL8QbkisDZwTXjtBR7PnRXGKd0tTsJr4hbHkBE6LIAo83xLEieJ8g9M/J9j+QrsAbO0bTBW9S/jw5n0eUzo1s4yjmfGy5CAZz1DCYrB5E94jD3H4Vxsw/iWagsVuGtO0SWvJ9sVJNmvNhvlKQudVeMV/q7tdbbFHo9cvLd8W1sDLz38aGKA2Bi4Hm0ySJxi3P45RVSzm+84rpP terraform-test-only"
}

run "creates_public_ip_when_enabled" {
  command = apply

  variables {
    public_ip = true
  }

  assert {
    condition     = length(azurerm_public_ip.pip) == 1
    error_message = "Existing callers must still create one public IP."
  }
  assert {
    condition     = azurerm_public_ip.pip[0].name == "test-vm-pip" && azurerm_public_ip.pip[0].allocation_method == "Static"
    error_message = "The managed IP name and static allocation must remain unchanged."
  }
  assert {
    condition     = azurerm_network_interface.main.ip_configuration[0].public_ip_address_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/publicIPAddresses/test-vm-pip" && output.public_ip == "192.0.2.10"
    error_message = "The NIC and output must use the module-created IP."
  }
}

run "no_public_ip_by_default" {
  command = apply

  assert {
    condition     = length(azurerm_public_ip.pip) == 0
    error_message = "The default configuration must not create a public IP."
  }
  assert {
    condition     = azurerm_network_interface.main.ip_configuration[0].public_ip_address_id == null && output.public_ip == null
    error_message = "The default configuration must have no public IP attachment or output."
  }
}

run "existing_ip_with_public_ip_true" {
  command = apply

  variables {
    public_ip = true
    existing_public_ip = {
      id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/publicIPAddresses/permanent-ip"
      ip_address = "192.0.2.20"
    }
  }

  assert {
    condition     = length(azurerm_public_ip.pip) == 0
    error_message = "An existing IP must not be managed by this module."
  }
  assert {
    condition     = azurerm_network_interface.main.ip_configuration[0].public_ip_address_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/publicIPAddresses/permanent-ip"
    error_message = "The NIC must attach the independently managed IP."
  }
  assert {
    condition     = output.public_ip == "192.0.2.20"
    error_message = "The public_ip output must return the existing IP address."
  }
}

run "existing_ip_with_public_ip_false" {
  command = apply

  variables {
    public_ip = false
    existing_public_ip = {
      id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/publicIPAddresses/permanent-ip"
      ip_address = "192.0.2.20"
    }
  }

  assert {
    condition     = length(azurerm_public_ip.pip) == 0
    error_message = "An existing IP must not be managed by this module."
  }
  assert {
    condition     = azurerm_network_interface.main.ip_configuration[0].public_ip_address_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/publicIPAddresses/permanent-ip"
    error_message = "The NIC must attach the independently managed IP."
  }
  assert {
    condition     = output.public_ip == "192.0.2.20"
    error_message = "The public_ip output must return the existing IP address."
  }
}
