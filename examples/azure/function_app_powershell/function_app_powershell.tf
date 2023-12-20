# --- RESOURCES / MODULES ---

module "function_app_powershell" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/function-app"
  source = "../../../azure/function-app"

  name                = "they-test-powershell"
  source_dir          = "../packages/function-app-powershell"
  location            = "Germany West Central"
  resource_group_name = "they-dev"

  build = {
    enabled = false
  }

  runtime = {
    name    = "powershell"
    version = "7.2"
  }

  tags = {
    Project   = "they-terraform-examples"
    CreatedBy = "terraform"
  }
}

# --- OUTPUT ---

output "endpoint_url_powershell" {
  value = "${module.function_app_powershell.endpoint_url}/api/hello-world?Name=World"
}
