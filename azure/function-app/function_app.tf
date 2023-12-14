# use data source to build and zip the function app,
# this way terraform can decide during plan stage
# if publishing is required or not
data "external" "builder" {
  count = var.build.enabled ? 1 : 0

  program = ["${path.module}/build.sh", var.source_dir, var.build.build_dir, var.build.command]
}

data "archive_file" "function_zip" {
  type        = "zip"
  output_path = coalesce(var.archive.output_path, "dist/${var.name}/azure-function-app.zip")
  source_dir  = var.source_dir
  excludes    = var.is_bundle ? concat(var.archive.excludes, ["**/node_modules/**", "**/.yarn/**"]) : var.archive.excludes

  depends_on = [data.external.builder]
}

resource "azurerm_windows_function_app" "function_app" {
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
      TriggerStorageConnection = data.azurerm_storage_account.trigger_storage_account.0.primary_connection_string
    } : {},
    var.identity != null ? {
      AZURE_CLIENT_ID = data.azurerm_user_assigned_identity.identity.0.client_id
    } : {},
    var.environment
  )

  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      type         = "UserAssigned"
      identity_ids = [data.azurerm_user_assigned_identity.identity.0.id]
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

locals {
  publish_code_command = "az webapp deployment source config-zip --resource-group ${var.resource_group_name} --name ${azurerm_windows_function_app.function_app.name} --src ${data.archive_file.function_zip.output_path}"
}
resource "null_resource" "function_app_publish" {
  triggers = {
    input_archive        = data.archive_file.function_zip.output_sha256
    publish_code_command = local.publish_code_command
  }

  provisioner "local-exec" {
    command = local.publish_code_command
  }

  depends_on = [local.publish_code_command]
}
