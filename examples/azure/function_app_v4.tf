# --- RESOURCES / MODULES ---

module "function_app_v4" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/function-app"
  source = "../../azure/function-app"

  name                = "they-test-v4"
  source_dir          = "packages/function-app-v4"
  location            = "Germany West Central"
  resource_group_name = "they-dev"
  environment = {
    AzureWebJobsFeatureFlags = "EnableWorkerIndexing"
  }
}

# --- OUTPUT ---

output "endpoint_url_v4" {
  value = "${module.function_app_v4.endpoint_url}/api/helloWorld"
}
