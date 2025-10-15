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
  scope                = var.target_container_app_job_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.trigger_identity.principal_id
}

module "trigger_function_app" {
  source = "../function-app"

  name                = var.name
  source_dir          = "${path.module}/trigger"
  location            = var.location
  resource_group_name = var.resource_group_name
  environment = {
    AzureWebJobsFeatureFlags = "EnableWorkerIndexing"
    AZURE_JOB_RESOURCE_ID    = var.target_container_app_job_id
  }
  is_bundle = true
  build = {
    enabled = true
    command = "yarn install --no-immutable && yarn run build" # yarn version can differ between local and ci
  }

  # Use the user-assigned identity we created above
  identity = {
    name = azurerm_user_assigned_identity.trigger_identity.name
  }

  tags = var.tags

  # Ensure the identity is fully created before the function app tries to reference it
  depends_on = [azurerm_user_assigned_identity.trigger_identity]
}
