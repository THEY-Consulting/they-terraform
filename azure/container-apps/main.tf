resource "azurerm_container_app" "container_app" {
  for_each = var.container_apps

  container_app_environment_id = azurerm_container_app_environment.app_environment.id
  name                         = each.value.name
  resource_group_name          = local.resource_group_name
  revision_mode                = each.value.revision_mode
  workload_profile_name        = each.value.workload_profile_name
  tags                         = var.tags

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

  dynamic "secret" {
    for_each = each.value.secret == null ? [] : each.value.secret

    content {
      name                = secret.value.name
      value               = secret.value.value
      key_vault_secret_id = secret.value.key_vault_secret_id
      identity            = secret.value.identity
    }
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

//Enables cors for container apps to specific origins
resource "null_resource" "cors_enabled" {
  for_each = {
    for k, v in var.container_apps : k => v
    if v.cors_enabled == true
  }

  //The idea was to use the wildcard * as allowed methods, since it is apparently allowed according to the documentation
  // but that produces weird results (in portal it shows as providers.tf, container_apps.tf, etc...)
  provisioner "local-exec" {
    command = "az containerapp ingress cors enable -n ${azurerm_container_app.container_app[each.key].name} -g ${local.resource_group_name} --allowed-origins ${each.value.cors_allowed_origins} --allowed-methods GET POST PUT DELETE PATCH"
  }

  depends_on = [
    azurerm_container_app.container_app, azurerm_container_app_custom_domain.main, azurerm_container_app_environment_certificate.app_environment_certificate,
  ]
}


