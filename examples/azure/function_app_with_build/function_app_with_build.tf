# --- RESOURCES / MODULES ---

module "function_app_with_build" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/function-app"
  source = "../../../azure/function-app"

  name                = "they-test-with-build"
  source_dir          = "../.packages/function-app-typescript"
  location            = "Germany West Central"
  resource_group_name = "they-dev"

  tags = {
    Project   = "they-terraform-examples"
    CreatedBy = "terraform"
  }
}

# --- OUTPUT ---

output "build" {
  value = module.function_app_with_build.build
}

output "endpoint_url_with_build" {
  value = "${module.function_app_with_build.endpoint_url}/api/hello-world"
}
