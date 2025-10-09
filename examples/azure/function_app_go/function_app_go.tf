# --- RESOURCES / MODULES ---

module "function_app_go" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/function-app"
  source = "../../../azure/function-app"

  name                = "they-test-go"
  source_dir          = "../.packages/function-app-go"
  location            = "Germany West Central"
  resource_group_name = "they-dev"

  runtime = {
    name    = "go"
    version = "1.23"  # Informational only - actual Go version determined by compiled binary
    os      = "linux"
  }

  build = {
    enabled = false  # Go binaries must be pre-compiled before deployment
  }

  tags = {
    Project   = "they-terraform-examples"
    CreatedBy = "terraform"
  }
}

# --- OUTPUT ---

output "endpoint_url_go" {
  value = "${module.function_app_go.endpoint_url}/api/hello-world?name=World"
}

