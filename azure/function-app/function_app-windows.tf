resource "azurerm_windows_function_app" "function_app" {
  count = var.runtime.os == "windows" ? 1 : 0

  name                = "${var.name}-windows-function-app"
  resource_group_name = var.resource_group_name
  location            = var.location

  storage_account_name       = data.azurerm_storage_account.storage_account.name
  storage_account_access_key = data.azurerm_storage_account.storage_account.primary_access_key
  service_plan_id            = data.azurerm_service_plan.service_plan.id

  app_settings = merge(
    {
      WEBSITE_RUN_FROM_PACKAGE                  = "1"
      WEBSITE_MAX_DYNAMIC_APPLICATION_SCALE_OUT = "1"
      AzureWebJobsDisableHomepage               = "true"
      "languageWorkers:node:arguments"          = "--max-old-space-size=1024"
    },
    var.storage_trigger != null ? {
      TriggerStorageConnection = local.trigger_storage_account.primary_connection_string
    } : {},
    var.identity != null ? {
      AZURE_CLIENT_ID = data.azurerm_user_assigned_identity.identity.0.client_id
    } : {},
    {
      STORAGE_ACCOUNT_NAME = data.azurerm_storage_account.storage_account.name
    },
    var.environment
  )

  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      type         = var.assign_system_identity ? "SystemAssigned, UserAssigned" : "UserAssigned"
      identity_ids = [data.azurerm_user_assigned_identity.identity.0.id]
    }
  }

  dynamic "identity" {
    for_each = var.assign_system_identity && var.identity == null ? [var.assign_system_identity] : []
    content {
      type = "SystemAssigned"
    }
  }

  site_config {
    application_insights_key = var.insights.enabled ? azurerm_application_insights.app_insights.0.instrumentation_key : null

    dynamic "application_stack" {
      for_each = var.runtime.name == "dotnet" ? [var.runtime] : []
      content {
        dotnet_version = application_stack.value.version
      }
    }

    dynamic "application_stack" {
      for_each = var.runtime.name == "java" ? [var.runtime] : []
      content {
        java_version = application_stack.value.version
      }
    }

    dynamic "application_stack" {
      for_each = var.runtime.name == "node" ? [var.runtime] : []
      content {
        node_version = application_stack.value.version
      }
    }

    dynamic "application_stack" {
      for_each = var.runtime.name == "powershell" ? [var.runtime] : []
      content {
        powershell_core_version = application_stack.value.version
      }
    }
  }

  # hidden-links are set by application insights automatically and would lead to continuous diffs -> set them explicitly
  # see: https://github.com/hashicorp/terraform-provider-azurerm/issues/16569
  tags = merge(var.tags, local.insights_tags)
}
