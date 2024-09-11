resource "azurerm_container_app_environment" "app_environment" {
  name                       = var.name
  location                   = local.resource_group_location
  resource_group_name        = local.resource_group_name
  log_analytics_workspace_id = var.enable_log_analytics ? azurerm_log_analytics_workspace.log_analytics_workspace[0].id : null
}

//TODO: how to fetch the path from somewhere else? Maybe Fileshare? or create secret (still wouldnt know how)?
resource "azurerm_container_app_environment_certificate" "example" {
  name                         = "app-env-cert"
  container_app_environment_id = azurerm_container_app_environment.app_environment.id
  certificate_blob_base64      = sensitive(filebase64("pathto/cert.pfx"))
  certificate_password         = ""
}

//CURRENTLY UNUSED RESOURCES
//data "azurerm_key_vault" "example" {
//  name                = "bdb-keyvault-elsa"
//  resource_group_name = "ELS-PROD-DOMAIN" //local.resource_group_name
//}
//
//data "azurerm_key_vault_certificate" "example" {
//  name         = "wildcard-bankenverband-de"
//  key_vault_id = data.azurerm_key_vault.example.id
//}


resource "azurerm_container_app" "container_app" {
  for_each = var.container_apps

  container_app_environment_id = azurerm_container_app_environment.app_environment.id
  name                         = each.value.name
  resource_group_name          = local.resource_group_name
  revision_mode                = each.value.revision_mode
  workload_profile_name        = each.value.workload_profile_name

  dynamic "identity" {
    for_each = each.value.identity == null ? [] : [each.value.identity]

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }
  dynamic "ingress" {
    for_each = each.value.ingress == null ? [] : [each.value.ingress]

    content {
      target_port                = ingress.value.target_port
      allow_insecure_connections = ingress.value.allow_insecure_connections
      external_enabled           = ingress.value.external_enabled
      transport                  = ingress.value.transport
      dynamic "traffic_weight" {
        for_each = ingress.value.traffic_weight == null ? [] : [ingress.value.traffic_weight]

        content {
          percentage      = traffic_weight.value.percentage
          label           = traffic_weight.value.label
          latest_revision = traffic_weight.value.latest_revision
          revision_suffix = traffic_weight.value.revision_suffix
        }
      }
      dynamic "ip_security_restriction" {
        for_each = ingress.value.ip_security_restrictions == null ? [] : ingress.value.ip_security_restrictions
        content {
          action           = ip_security_restriction.value.action
          ip_address_range = ip_security_restriction.value.ip_address_range
          name             = ip_security_restriction.value.name
          description      = ip_security_restriction.value.description
        }
      }
    }
  }
  dynamic "registry" {
    for_each = each.value.registry == null ? [] : each.value.registry

    content {
      server               = registry.value.server
      identity             = registry.value.identity
      password_secret_name = registry.value.password_secret_name
      username             = registry.value.username
    }
  }

  secret {
    name  = each.value.secret.name
    value = each.value.secret.value
  }
  template {
    max_replicas = each.value.template.max_replicas
    min_replicas = each.value.template.min_replicas

    dynamic "container" {
      for_each = each.value.template.containers

      content {
        cpu    = container.value.cpu
        image  = container.value.image
        memory = container.value.memory
        name   = container.value.name

        dynamic "env" {
          for_each = container.value.env == null ? [] : container.value.env

          content {
            name        = env.value.name
            secret_name = env.value.secret_name
            value       = env.value.value
          }
        }
      }
    }
  }
}

# TODO: change to Workload profile, we are currently using Consumption profile.
