# --- Storage Container for static web frontend ---
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

# --- Front Door Profile (to be shared between frontend and backend) ---
resource "azurerm_cdn_frontdoor_profile" "shared_profile" {
  name                     = "${terraform.workspace}-shared-profile"
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

# --- Front Door for Web Frontend ---
module "frontdoor_web" {
  source = "../../../azure/frontdoor"

  resource_group = {
    name     = "they-dev"
    location = "Germany West Central"
  }

  # Use shared Front Door profile
  frontdoor_profile = {
    id   = azurerm_cdn_frontdoor_profile.shared_profile.id
    name = azurerm_cdn_frontdoor_profile.shared_profile.name
  }

  # Web configuration for static website
  web = {
    primary_web_host = data.azurerm_storage_account.web.primary_web_host
  }

  # Base domain name without subdomain
  domain = "they-azure"

  # Subdomain configuration
  subdomain = "www-${terraform.workspace}"

  # DNS zone configuration - if you have an existing DNS zone
  dns_zone_name           = "they-azure.de"
  dns_zone_resource_group = "they-dev"

  # Cache settings for static content (optional, has defaults)
  cache_settings = {
    query_string_caching_behavior = "IgnoreQueryString"
    compression_enabled           = true
    content_types_to_compress     = ["text/html", "text/css", "application/javascript", "image/svg+xml"]
  }
}

# --- Mock Backend Example (simulating an API service) ---
resource "azurerm_public_ip" "mock_backend" {
  name                = "mock-backend-${terraform.workspace}"
  resource_group_name = "they-dev"
  location            = "Germany West Central"
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    createdBy   = "Terraform"
    environment = "dev"
  }
}

# --- Front Door for Backend API ---
module "frontdoor_backend" {
  source = "../../../azure/frontdoor"

  resource_group = {
    name     = "they-dev"
    location = "Germany West Central"
  }

  # Use the same shared Front Door profile
  frontdoor_profile = {
    id   = azurerm_cdn_frontdoor_profile.shared_profile.id
    name = azurerm_cdn_frontdoor_profile.shared_profile.name
  }

  # Backend configuration for API service
  backend = {
    host                          = azurerm_public_ip.mock_backend.ip_address
    host_header                   = azurerm_public_ip.mock_backend.ip_address
    certificate_name_check_enabled = false
    forwarding_protocol           = "HttpOnly"
    http_port                     = 80
    https_port                    = 443
    health_probe = {
      path         = "/"
      interval     = 120
      protocol     = "Http"
      request_type = "GET"
    }
  }

  # API-specific cache settings (minimal caching for API)
  cache_settings = {
    query_string_caching_behavior = "IgnoreQueryString"
    compression_enabled           = true
    content_types_to_compress     = ["application/json", "text/plain"]
  }

  # Domain configuration
  domain                  = "they-azure"
  subdomain               = "api-${terraform.workspace}"
  dns_zone_name           = "they-azure.de"
  dns_zone_resource_group = "they-dev"
}

# Upload sample content to the storage account
resource "azurerm_storage_blob" "blobobject" {
  name                   = "index.html"
  storage_account_name   = module.storage_container.storage_account_name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "index.html"
  content_type           = "text/html"
  access_tier            = "Hot"

  depends_on = [module.frontdoor_web, module.storage_container]
}

# Outputs for frontend and backend
output "frontend_url" {
  value = module.frontdoor_web.custom_domain_url
}

output "backend_url" {
  value = module.frontdoor_backend.custom_domain_url
}

output "shared_profile_id" {
  value = azurerm_cdn_frontdoor_profile.shared_profile.id
}

output "shared_profile_name" {
  value = azurerm_cdn_frontdoor_profile.shared_profile.name
}
