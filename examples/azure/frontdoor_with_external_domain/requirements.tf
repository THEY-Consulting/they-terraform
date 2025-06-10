# --- Storage Container for static web frontend ---
module "storage_container" {
  source = "../../../azure/storage-container"

  name                = "they-test-frontdoor-${terraform.workspace}"
  resource_group_name = "they-dev"
  location            = "Germany West Central"

  container_access_type = "private"
  metadata = {
    environment = "dev"
    department  = "it"
  }

  storage_account = {
    preexisting_name = null # If null, a new storage account will be created
    tier             = "Standard"
    replication_type = "RAGRS"
    kind             = "StorageV2"
    access_tier      = "Hot"
    is_hns_enabled   = false

    # CORS configuration
    cors_rules = [{
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "POST", "PUT"]
      allowed_origins    = ["https://they-azure.de"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }]
  }

  enable_static_website = true

  tags = {
    createdBy   = "Terraform"
    environment = "dev"
  }
}

# --- Front Door Profile (to be shared between frontend and backend) ---
resource "azurerm_cdn_frontdoor_profile" "shared_profile" {
  name                     = "they-test-frontdoor-with-external-domain-${terraform.workspace}"
  resource_group_name      = "they-dev"
  response_timeout_seconds = 16
  sku_name                 = "Standard_AzureFrontDoor"

  tags = {
    createdBy   = "Terraform"
    environment = "dev"
  }
}

# --- Read Storage Account Details ---
data "azurerm_storage_account" "web" {
  name                = module.storage_container.storage_account_name
  resource_group_name = "they-dev"
  depends_on          = [module.storage_container]
}
