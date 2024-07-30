resource "azurerm_container_group" "container_group" {
  name                = var.name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  ip_address_type     = var.ip_address_type
  os_type             = var.os_type 
  exposed_port = var.exposed_port

  dynamic "diagnostics" {
    for_each = var.enable_log_analytics ? [1] : []
    content {
      log_analytics {
        workspace_id  = azurerm_log_analytics_workspace.log_analytics_workspace[0].workspace_id
        workspace_key = azurerm_log_analytics_workspace.log_analytics_workspace[0].primary_shared_key
      }
    }
  }

  dynamic "image_registry_credential" {
  for_each = var.registry_credential[*]

  content {
    username = var.registry_credential.username
    password = var.registry_credential.password
    server   = var.registry_credential.server
  }
  }

  dynamic "container" {
    for_each = var.containers

    content {
      name   = container.value.name
      image  = container.value.image
      cpu    = container.value.cpu
      memory = container.value.memory
      environment_variables = container.value.environment_variables

      ports {
        port     = container.value.ports.port
        protocol = container.value.ports.protocol
      }

      dynamic "readiness_probe" {
        for_each = container.value.readiness_probe != null ? [container.value.readiness_probe] : []
        content {
          exec = readiness_probe.value.exec
          dynamic "http_get" {
            for_each = readiness_probe.value.http_get[*]
            content {
              path         = http_get.value.path
              port         = http_get.value.port
              scheme       = http_get.value.scheme
              http_headers = http_get.value.http_headers
            }
          }
          initial_delay_seconds = readiness_probe.value.initial_delay_seconds
          period_seconds        = readiness_probe.value.period_seconds
          failure_threshold     = readiness_probe.value.failure_threshold
          success_threshold     = readiness_probe.value.success_threshold
          timeout_seconds       = readiness_probe.value.timeout_seconds
        }
      }

      dynamic "liveness_probe" {
        for_each = container.value.liveness_probe != null ? [container.value.liveness_probe] : []
        content {
          exec = liveness_probe.value.exec
          dynamic "http_get" {
            for_each = liveness_probe.value.http_get[*]
            content {
              path         = http_get.value.path
              port         = http_get.value.port
              scheme       = http_get.value.scheme
              http_headers = http_get.value.http_headers
            }
          }
          initial_delay_seconds = liveness_probe.value.initial_delay_seconds
          period_seconds        = liveness_probe.value.period_seconds
          failure_threshold     = liveness_probe.value.failure_threshold
          success_threshold     = liveness_probe.value.success_threshold
          timeout_seconds       = liveness_probe.value.timeout_seconds
        }
      }
    }
  }

  tags = var.tags
}

