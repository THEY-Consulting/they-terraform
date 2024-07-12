resource "azurerm_resource_group" "resource_group" {
  name     = var.name
  location = var.location
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
resource "azurerm_container_app" "app" {
  name                         = var.name
  container_app_environment_id = azurerm_container_app_environment.app_environment.id
  resource_group_name          = azurerm_resource_group.resource_group.name
  revision_mode                = "Single" # TODO: Check this field later!
  ingress {
    external_enabled = true
    target_port = 80
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }

  template {
    container {
      # TODO: Modify this field.
      name   = "whoami"
      # TODO: Modify this field.
      image  = "traefik/whoami:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }
}
