# --- RESOURCES / MODULES ---

module "diagnostics" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/monitoring/datadog"
  source = "../../../azure/monitoring/datadog"

  eventhub_namespace_name = "they-test"
  handler_name            = "datadog-importer-they-test"
  location                = "Germany West Central"
  resource_group_name     = "they-dev"

  dd_api_key = var.dd_api_key
  dd_service = "they-terraform-examples"

  tags = {
    Project   = "they-terraform-examples"
    CreatedBy = "terraform"
  }
}

module "function_app_with_diagnostics" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/function-app"
  source = "../../../azure/function-app"

  name                = "they-test-with-diagnostics"
  source_dir          = "../.packages/function-app-v4"
  location            = "Germany West Central"
  resource_group_name = "they-dev"
  environment = {
    AzureWebJobsFeatureFlags = "EnableWorkerIndexing"
  }

  diagnostics = module.diagnostics.diagnostics

  tags = {
    Project   = "they-terraform-examples"
    CreatedBy = "terraform"
  }

  depends_on = [
    module.diagnostics
  ]
}

# --- OUTPUT ---

output "endpoint_url_with_diagnostics" {
  value = "${module.function_app_with_diagnostics.endpoint_url}/api/helloWorld"
}
