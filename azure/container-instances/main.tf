data "azurerm_container_registry" "acr" {
  name                = var.username # maybe change var?
  resource_group_name = var.acr_resource_group
}

resource "azurerm_resource_group" "resource_group" {
  name     = var.name
  location = var.location
}

resource "azurerm_container_group" "container_group" {
  name                = var.name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  ip_address_type     = var.ip_address_type
  os_type             = var.os_type 
  exposed_port = [{
      port     = 3000 #var.exposed_port
      protocol = "TCP"#var.protocol
    },{
     port     = 8181 #var.exposed_port
      protocol = "TCP"#var.protocol
    }
    ]

  image_registry_credential {
    server   =  data.azurerm_container_registry.acr.login_server #var.container_registry_server
    username = var.username
    password = var.password
  }


  dynamic "container" {
    for_each = var.containers

    content {
      name   = container.value.name
      image  = "${data.azurerm_container_registry.acr.login_server}/${container.value.image}"
      cpu    = container.value.cpu
      memory = container.value.memory
      environment_variables = container.value.environment_variables

      ports {
        port     = container.value.ports.port
        protocol = container.value.ports.protocol
      }

      dynamic "liveness_probe" {
        for_each = container.value.liveness_probe != null ? [container.value.liveness_probe] : []
        content {
          http_get {
            path   = liveness_probe.value.path
            port   = liveness_probe.value.port
            scheme = liveness_probe.value.scheme
          }
          initial_delay_seconds = liveness_probe.value.initial_delay_seconds
          period_seconds        = liveness_probe.value.period_seconds
          success_threshold = liveness_probe.value.success_threshold
          failure_threshold = liveness_probe.value.failure_threshold
        }
      }

      dynamic "readiness_probe" {
        for_each = container.value.readiness_probe != null ? [container.value.readiness_probe] : []
        content {
          http_get {
            path   = readiness_probe.value.path
            port   = readiness_probe.value.port
            scheme = readiness_probe.value.scheme
          }
          initial_delay_seconds = readiness_probe.value.initial_delay_seconds
          period_seconds        = readiness_probe.value.period_seconds
          success_threshold = readiness_probe.value.success_threshold
          failure_threshold = readiness_probe.value.failure_threshold
        }
      }
    }
  }

  tags = var.tags
}


# TODO: change to Workload profile, we are currently using Consumption profile.
