# Get current Azure client configuration for tenant ID
data "azurerm_client_config" "current" {}

resource "azurerm_container_app_job" "container_app_job" {
  for_each = var.jobs

  container_app_environment_id = var.container_app_environment_id != null ? var.container_app_environment_id : azurerm_container_app_environment.app_environment[0].id
  name                         = each.value.name
  resource_group_name          = local.resource_group_name
  location                     = local.resource_group_location
  replica_timeout_in_seconds   = each.value.replica_timeout
  replica_retry_limit          = each.value.replica_retry_limit
  workload_profile_name        = each.value.workload_profile_name
  tags                         = merge(var.tags, each.value.tags)

  # Manual trigger configuration
  dynamic "manual_trigger_config" {
    for_each = each.value.manual_trigger_config != null ? [each.value.manual_trigger_config] : []

    content {
      parallelism              = manual_trigger_config.value.parallelism
      replica_completion_count = manual_trigger_config.value.replica_completion_count
    }
  }

  # Schedule trigger configuration
  dynamic "schedule_trigger_config" {
    for_each = each.value.schedule_trigger_config != null ? [each.value.schedule_trigger_config] : []

    content {
      cron_expression          = schedule_trigger_config.value.cron_expression
      parallelism              = schedule_trigger_config.value.parallelism
      replica_completion_count = schedule_trigger_config.value.replica_completion_count
    }
  }

  # Event trigger configuration
  dynamic "event_trigger_config" {
    for_each = each.value.event_trigger_config != null ? [each.value.event_trigger_config] : []

    content {
      parallelism              = event_trigger_config.value.parallelism
      replica_completion_count = event_trigger_config.value.replica_completion_count

      scale {
        min_executions = event_trigger_config.value.scale.min_executions
        max_executions = event_trigger_config.value.scale.max_executions

        dynamic "rules" {
          for_each = event_trigger_config.value.scale.rules

          content {
            name             = rules.value.name
            custom_rule_type = rules.value.type
            metadata         = rules.value.metadata

            dynamic "authentication" {
              for_each = rules.value.auth

              content {
                secret_name       = authentication.value.secret_name
                trigger_parameter = authentication.value.trigger_parameter
              }
            }
          }
        }
      }
    }
  }

  # Identity configuration - use shared user-assigned identity when ACR integration or role assignments are configured
  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : (
      var.acr_integration != null || length(var.role_assignments) > 0 ? [{
        type         = "UserAssigned"
        identity_ids = [azurerm_user_assigned_identity.shared_identity[0].id]
        }] : (
        var.auto_assign_system_identity ? [{
          type         = "SystemAssigned"
          identity_ids = null
        }] : []
      )
    )

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  # Registry configuration - merge auto-config with manual config
  dynamic "registry" {
    for_each = concat(
      var.acr_integration != null ? [
        {
          server               = var.acr_integration.login_server
          identity             = azurerm_user_assigned_identity.shared_identity[0].id
          username             = null
          password_secret_name = null
        }
      ] : [],
      each.value.registry != null ? each.value.registry : []
    )

    content {
      server               = registry.value.server
      identity             = registry.value.identity
      password_secret_name = registry.value.password_secret_name
      username             = registry.value.username
    }
  }

  # Secrets configuration
  dynamic "secret" {
    for_each = nonsensitive(var.secrets)

    content {
      name                = secret.value.name
      value               = secret.value.value
      key_vault_secret_id = secret.value.key_vault_secret_id
      identity            = secret.value.identity
    }
  }

  # Template configuration
  template {
    dynamic "container" {
      for_each = each.value.template.containers

      content {
        cpu     = container.value.cpu
        image   = container.value.image
        memory  = container.value.memory
        name    = container.value.name
        command = container.value.command
        args    = container.value.args

        dynamic "env" {
          for_each = concat(
            # User-defined environment variables
            container.value.env == null ? [] : container.value.env,
            # Auto-inject Azure authentication environment variables when using user-assigned identity
            (var.acr_integration != null || length(var.role_assignments) > 0) && each.value.identity == null ? [
              {
                name        = "AZURE_CLIENT_ID"
                value       = azurerm_user_assigned_identity.shared_identity[0].client_id
                secret_name = null
              },
              {
                name        = "AZURE_TENANT_ID"
                value       = data.azurerm_client_config.current.tenant_id
                secret_name = null
              }
            ] : []
          )

          content {
            name        = env.value.name
            value       = env.value.value
            secret_name = env.value.secret_name
          }
        }
      }
    }
  }

  # Ensure ACR role assignment is created before the container app job
  # This prevents image pull failures during job creation
  depends_on = [azurerm_role_assignment.acr_pull]
}
