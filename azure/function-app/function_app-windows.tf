resource "azurerm_windows_function_app" "function_app" {
  count = var.runtime.os == "windows" ? 1 : 0

  name                = local.name
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

  // This is used to configure the AzureWebJobsDashboard setting.
  // Since it is deprecated, we disable it
  builtin_logging_enabled = false

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

    application_stack {
      dotnet_version          = var.runtime.name == "dotnet" ? var.runtime.version : null
      java_version            = var.runtime.name == "java" ? var.runtime.version : null
      node_version            = var.runtime.name == "node" ? var.runtime.version : null
      powershell_core_version = var.runtime.name == "powershell" ? var.runtime.version : null
    }

    # required to be able to trigger the function app from the portal
    cors {
      allowed_origins = [
        "https://portal.azure.com",
      ]
      support_credentials = false
    }

  }

  # hidden-links are set by application insights automatically and would lead to continuous diffs -> set them explicitly
  # see: https://github.com/hashicorp/terraform-provider-azurerm/issues/16569
  tags = merge(var.tags, local.insights_tags)
}
