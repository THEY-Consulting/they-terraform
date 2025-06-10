locals {
  subdomain = "frontdoor-${terraform.workspace}"
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
  domain               = "they-azure"
  is_external_dns_zone = true

  # Subdomain configuration
  subdomain = local.subdomain

  # DNS zone configuration - if you have an existing DNS zone
  dns_zone_name = "they-azure.de"

  # Cache settings for static content (optional, has defaults)
  cache_settings = {
    query_string_caching_behavior = "IgnoreQueryString"
    compression_enabled           = true
    content_types_to_compress     = ["text/html", "text/css", "application/javascript", "image/svg+xml"]
  }
}

# Simulate DNS zone in another azure account
module "frontdoor_domain" {
  source = "../../../azure/frontdoor-domain"

  resource_group_name = "they-dev"
  dns_zone_name       = "they-azure.de"
  subdomain           = local.subdomain
  frontdoor_host_name = module.frontdoor_web.endpoint_host_name
  validation_token    = module.frontdoor_web.custom_domain_validation_token
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

output "shared_profile_id" {
  value = azurerm_cdn_frontdoor_profile.shared_profile.id
}

output "shared_profile_name" {
  value = azurerm_cdn_frontdoor_profile.shared_profile.name
}
