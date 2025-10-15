# Create a user-assigned managed identity for the trigger function
# This allows us to assign roles to it before the function app is created
resource "azurerm_user_assigned_identity" "trigger_identity" {
  name                = "${var.name}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Grant the identity permission to trigger the Container Apps Job
resource "azurerm_role_assignment" "trigger_job_contributor" {
  scope                = var.target.container_app_environment_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.trigger_identity.principal_id
}

module "calculate_statistics_trigger_function_app" {
  source = "../function-app"

  name                = var.name
  source_dir          = "${path.module}/trigger"
  location            = var.location
  resource_group_name = var.resource_group_name
  environment = {
    AzureWebJobsFeatureFlags = "EnableWorkerIndexing"
    SENTRY_DSN               = var.sentry_dsn
    SENTRY_ENV               = var.sentry_env
    ENVIRONMENT              = var.environment
    VERSION                  = var.version_tag
    AZURE_SUBSCRIPTION_ID    = var.target.subscription_id
    AZURE_RESOURCE_GROUP     = var.target.resource_group_name
    AZURE_JOB_NAME           = var.target.name
  }
  is_bundle = true
  build = {
    enabled = false # we build the function app manually to reduce deployment time
  }

  # Use the user-assigned identity we created above
  identity = {
    name = azurerm_user_assigned_identity.trigger_identity.name
  }

  tags = var.tags

  # Ensure the identity is fully created before the function app tries to reference it
  depends_on = [azurerm_user_assigned_identity.trigger_identity]
}
