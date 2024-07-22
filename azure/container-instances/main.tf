data "azurerm_container_registry" "acr_test_bdb" {
  name                = var.username # maybe change var?
  resource_group_name = "MSO-test"
}

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
  name                = "${var.name}-backend"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  ip_address_type     = "Public"
  os_type             = "Linux"
  exposed_port = [{
      port     = 3000
      protocol = "TCP"
    }]

  image_registry_credential {
    server   =  data.azurerm_container_registry.acr_test_bdb.login_server #var.container_registry_server
    username = var.username
    password = var.password
  }


  container {
    name   = "backend-test"
    image  = "${data.azurerm_container_registry.acr_test_bdb.login_server}/backend-test:latest"
    cpu    = "1"
    memory = "2"
    environment_variables= var.environment_variables_backend

    ports {
      port     = 8181
      protocol = "TCP"
    }
  }

   container {
    name   = "frontend-test"
    image  = "${data.azurerm_container_registry.acr_test_bdb.login_server}/frontend-test:latest"
    cpu    = "2"
    memory = "4"
    environment_variables= var.environment_variables_frontend

    ports {
      port     = 3000
      protocol = "TCP"
    }
  }

  tags = {
    environment = "testing"
  }
}
/*
resource "azurerm_container_group" "frontend" {
  name                = "${var.name}-frontend"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  ip_address_type     = "Public"
  os_type             = "Linux"

  image_registry_credential {
    server   = data.azurerm_container_registry.acr_test_bdb.login_server
    username = var.username
    password = var.password
  }

  container {
    name   = "frontend-test"
    image  = "${data.azurerm_container_registry.acr_test_bdb.login_server}/frontend-test:latest"
    cpu    = "2"
    memory = "4"
    environment_variables= var.environment_variables_frontend

    ports {
      port     = 3000
      protocol = "TCP"
    }
  }

  tags = {
    environment = "testing"
  }
}
*/

#resource "azurerm_role_assignment" "acr_pull" {
#  principal_id         = azurerm_user_assigned_identity.assigned_identity.principal_id
#  role_definition_name = "AcrPull"
#  scope                = data.azurerm_container_registry.acr_test_bdb.id
#}


# TODO: change to Workload profile, we are currently using Consumption profile.
