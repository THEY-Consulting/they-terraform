# --- RESOURCES / MODULES ---

module "function_app_without_build" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/function-app"
  source = "../../azure/function-app"

  name                = "they-test-no-build"
  source_dir          = "packages/function-app-simple"
  location            = "Germany West Central"
  resource_group_name = "they-dev"

  build = {
    enabled = false
  }
}

# --- OUTPUT ---

output "function_app_id" {
  value = module.function_app_without_build.id
}

output "archive_file_path" {
  value = module.function_app_without_build.archive_file_path
}

output "endpoint_url" {
  value = "${module.function_app_without_build.endpoint_url}/api/hello-world"
}
