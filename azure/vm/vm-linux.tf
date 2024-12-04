resource "azurerm_linux_virtual_machine" "main" {
  count = var.vm_os == "linux" ? 1 : 0

  name                = "${var.name}-vm"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  computer_name       = coalesce(var.vm_hostname, var.name)
  size                = var.vm_size
  admin_username      = var.vm_username
  admin_password      = var.vm_password
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]
  custom_data = var.custom_data

  admin_ssh_key {
    username   = var.vm_username
    public_key = var.vm_public_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.vm_image.publisher
    offer     = var.vm_image.offer
    sku       = var.vm_image.sku
    version   = var.vm_image.version
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.vm_public_ssh_key != null
      error_message = "You must provide a public SSH key in order to provision a Linux VM."
    }
  }
}
