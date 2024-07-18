#data "azurerm_container_registry" "acr_test_bdb" {
#  name                = "testbdb"
#  resource_group_name = "MSO-test"
#}

resource "azurerm_resource_group" "resource_group" {
  name     = var.name
  location = var.location
}

#resource "azurerm_user_assigned_identity" "assigned_identity" {
#  name                = "managed-identity-test"
#  resource_group_name = azurerm_resource_group.resource_group.name
#  location            = azurerm_resource_group.resource_group.location
#}

resource "azurerm_container_group" "backend" {
  name                = var.name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  ip_address_type     = "Public"
  dns_name_label      = "aci-label"
  os_type             = "Linux"

  #identity {
  #  type         = "UserAssigned"
  #  identity_ids = [azurerm_user_assigned_identity.assigned_identity.id]
  #}

  #image_registry_credential {
  #  #user_assigned_identity_id = azurerm_user_assigned_identity.assigned_identity.id
  #  server   = var.container_registry_server
  #  username = var.username
  #  password = var.password
  #}

  container {
    name   = "hello-world" #"backend-test"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest" #"testbdb.azurecr.io/backend-test:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 443
      protocol = "TCP"
    }
  }

  #container {
  #  name   = "sidecar"
  #  image  = "mcr.microsoft.com/azuredocs/aci-tutorial-sidecar"
  #  cpu    = "0.5"
  #  memory = "1.5"
  #}

  tags = {
    environment = "testing"
  }
}

#resource "azurerm_role_assignment" "acr_pull" {
#  principal_id         = azurerm_user_assigned_identity.assigned_identity.principal_id
#  role_definition_name = "AcrPull"
#  scope                = data.azurerm_container_registry.acr_test_bdb.id
#}


# TODO: change to Workload profile, we are currently using Consumption profile.
