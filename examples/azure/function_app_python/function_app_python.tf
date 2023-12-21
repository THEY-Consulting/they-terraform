# --- RESOURCES / MODULES ---

module "function_app_python" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/function-app"
  source = "../../../azure/function-app"

  name                = "they-test-python"
  source_dir          = "../packages/function-app-python"
  location            = "Germany West Central"
  resource_group_name = "they-dev"

  runtime = {
    name    = "python"
    version = "3.11"
    os      = "linux"
  }

  build = {
    enabled = false
  }

  tags = {
    Project   = "they-terraform-examples"
    CreatedBy = "terraform"
  }
}

# --- OUTPUT ---

output "endpoint_url_python" {
  value = "${module.function_app_python.endpoint_url}/api/helloWorld?user=World"
}
