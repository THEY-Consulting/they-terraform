# --- Storage Container ---
module "storage_container" {
  source = "../../../azure/storage-container"

  name                = "${terraform.workspace}-storage-container"
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

# --- Front Door ---
data "azurerm_storage_account" "web" {
  name                = module.storage_container.storage_account_name
  resource_group_name = "they-dev"
  depends_on          = [module.storage_container]
}

module "frontdoor" {
  source = "../../../azure/frontdoor"

  resource_group = {
    name     = "they-dev"
    location = "Germany West Central"
  }

  storage_account = {
    primary_web_host = data.azurerm_storage_account.web.primary_web_host
  }

  # Base domain name without subdomain
  domain = "they-azure"

  # Subdomain configuration
  subdomain = terraform.workspace

  # DNS zone configuration - if you have an existing DNS zone
  dns_zone_name           = "they-azure.de"
  dns_zone_resource_group = "they-dev"
}

# Additional outputs for the front door
output "frontdoor_endpoint_url" {
  value = module.frontdoor.endpoint_url
}

output "frontdoor_custom_domain_url" {
  value = module.frontdoor.custom_domain_url
}
