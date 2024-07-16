data "azurerm_container_registry" "acr_test_bdb" {
  name                = "testbdb"
  resource_group_name = "MSO-test"
}
resource "azurerm_resource_group" "resource_group" {
  name     = var.name
  location = var.location
}

resource "azurerm_user_assigned_identity" "assigned_identity" {
  name                = "managed-identity-test"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
}

resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = var.name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "PerGB2018" # TODO: Check this field later!
  retention_in_days   = var.log_retention
}

resource "azurerm_container_app_environment" "app_environment" {
  name                       = var.name
  location                   = azurerm_resource_group.resource_group.location
  resource_group_name        = azurerm_resource_group.resource_group.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id
}
resource "azurerm_container_app" "backend" {
  name                         = "${var.name}-be"
  container_app_environment_id = azurerm_container_app_environment.app_environment.id
  resource_group_name          = azurerm_resource_group.resource_group.name
  revision_mode                = "Single" # TODO: Check this field later!
  ingress {
    external_enabled = true
    target_port = 8181 #test for backend
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.assigned_identity.id]
  }

  registry {
    identity = azurerm_user_assigned_identity.assigned_identity.id
    server   = var.container_registry_server
  }

  template {
    container {
      # TODO: Modify this field.
      name   = "backend-test"
      # TODO: Modify this field.
      image  = "${data.azurerm_container_registry.acr_test_bdb.login_server}/backend-test:latest"
      cpu    = 0.5
      memory = "1.0Gi"
    }
  }
}

#frontend
resource "azurerm_container_app" "frontend" {
  name                         = "${var.name}-fe"
  container_app_environment_id = azurerm_container_app_environment.app_environment.id
  resource_group_name          = azurerm_resource_group.resource_group.name
  revision_mode                = "Single" # TODO: Check this field later!
  ingress {
    external_enabled = true
    target_port = 3000 #test for frontend
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.assigned_identity.id]
  }

  registry {
    identity = azurerm_user_assigned_identity.assigned_identity.id
    server   = var.container_registry_server
  }

  template {
    container {
      # TODO: Modify this field.
      name   = "frontend-test"
      # TODO: Modify this field.
      image  = "${data.azurerm_container_registry.acr_test_bdb.login_server}/frontend-test:latest"
      cpu    = 2
      memory = "4.0Gi" #NOTE: to prevent following error: FATAL ERROR: Reached heap limit Allocation failed - JavaScript heap out of memory

      env {
        name  = "REACT_APP_API_BASE_URL"
        value = "http://backend-test:8181"
      }

      env {
        name  = "REACT_APP_ENV" 
        value = "ANOTHER_ENV_VAR_VALUE"
      }
    }
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = azurerm_user_assigned_identity.assigned_identity.principal_id
  role_definition_name = "AcrPull"
  scope                = data.azurerm_container_registry.acr_test_bdb.id
}


# TODO: change to Workload profile, we are currently using Consumption profile.
