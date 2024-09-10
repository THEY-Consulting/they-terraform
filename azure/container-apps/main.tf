resource "azurerm_container_app_environment" "app_environment" {
  name                       = var.name
  location                   = local.resource_group_location
  resource_group_name        = local.resource_group_name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id
}

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

# creates binding from custom domain to container app, see comment in azurerm_container_app for more info
resource "null_resource" "create_certificate_binding" {
  for_each = var.dns_zone != null ? var.container_apps : {}

  provisioner "local-exec" {
    command = "az containerapp hostname bind --hostname ${each.value.subdomain}.${var.dns_zone.existing_dns_zone_name} -g ${local.resource_group_name} -n ${azurerm_container_app.container_app[each.key].name} --environment ${azurerm_container_app_environment.app_environment.name} --validation-method CNAME"
  }

  depends_on = [azurerm_container_app.container_app, azurerm_container_app_custom_domain.main]
}

data "azurerm_dns_zone" "main" {
  count               = var.dns_zone != null ? 1 : 0
  name                = var.dns_zone.existing_dns_zone_name
  resource_group_name = var.dns_zone.existing_dns_zone_resource_group_name
}

# https://learn.microsoft.com/en-us/azure/container-apps/custom-domains-managed-certificates?pivots=azure-portal
resource "azurerm_dns_txt_record" "main" {
  for_each            = var.dns_zone != null ? var.container_apps : {}
  name                = "asuid.${each.value.subdomain}" # asuid. is azure specific and required as prefix
  resource_group_name = data.azurerm_dns_zone.main[0].resource_group_name
  zone_name           = data.azurerm_dns_zone.main[0].name
  ttl                 = 300

  record {
    value = azurerm_container_app_environment.app_environment.custom_domain_verification_id
  }
}

resource "azurerm_dns_cname_record" "main" {
  for_each            = var.dns_zone != null ? var.container_apps : {}
  name                = each.value.subdomain
  resource_group_name = data.azurerm_dns_zone.main[0].resource_group_name
  zone_name           = data.azurerm_dns_zone.main[0].name
  ttl                 = 300

  record = azurerm_container_app.container_app[each.key].latest_revision_fqdn
}

resource "azurerm_container_app_custom_domain" "main" {
  //# TODO: replace with variable for URL or HOSTNAME
  for_each         = var.dns_zone != null ? var.container_apps : {}
  name             = "${each.value.subdomain}.${var.dns_zone.existing_dns_zone_name}"
  container_app_id = azurerm_container_app.container_app[each.key].id
  lifecycle {
    // When using an Azure created Managed Certificate these values must be added to ignore_changes to prevent resource recreation.
    // src: https://registry.terraform.io/providers/hashicorp/azurerm/3.116.0/docs/resources/container_app_custom_domain
    ignore_changes = [certificate_binding_type, container_app_environment_certificate_id]
  }
}

# TODO: change to Workload profile, we are currently using Consumption profile.
