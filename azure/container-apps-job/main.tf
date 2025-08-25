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

  # Identity configuration
  dynamic "identity" {
    for_each = each.value.identity == null ? [] : [each.value.identity]

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  # Registry configuration
  dynamic "registry" {
    for_each = each.value.registry == null ? [] : each.value.registry

    content {
      server               = registry.value.server
      identity             = registry.value.identity
      password_secret_name = registry.value.password_secret_name
      username             = registry.value.username
    }
  }

  # Secrets configuration
  dynamic "secret" {
    for_each = each.value.secret == null ? [] : each.value.secret

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
