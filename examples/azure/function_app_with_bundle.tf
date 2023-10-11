# --- RESOURCES / MODULES ---

module "function_app_with_bundle" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/function-app"
  source = "../../azure/function-app"

  name                = "they-test-with-bundle"
  source_dir          = "packages/function-app-bundle"
  location            = "Germany West Central"
  resource_group_name = "they-dev"
}

# --- OUTPUT ---

output "endpoint_url_with_bundle" {
  value = "${module.function_app_with_bundle.endpoint_url}/api/hello-world"
}
