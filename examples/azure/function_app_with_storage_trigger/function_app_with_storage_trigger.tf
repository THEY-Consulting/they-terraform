# --- RESOURCES / MODULES ---

module "function_app_with_storage_trigger" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/function-app"
  source = "../../../azure/function-app"

  name                = "they-test-storage-trigger"
  source_dir          = "../.packages/function-app-with-trigger"
  location            = "Germany West Central"
  resource_group_name = "they-dev"

  storage_trigger = {
    function_name = "hello-world"
    events        = ["Microsoft.Storage.BlobCreated"]
  }

  tags = {
    Project   = "they-terraform-examples"
    CreatedBy = "terraform"
  }
}

# --- OUTPUT ---
