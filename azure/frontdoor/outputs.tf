output "endpoint_url" {
  description = "The URL of the Front Door endpoint"
  value       = "https://${azurerm_cdn_frontdoor_endpoint.web_endpoint.host_name}"
}

output "custom_domain_url" {
  description = "The URL of the custom domain"
  value       = "https://${local.full_domain_name}"
}

output "cdn_frontdoor_profile_id" {
  description = "The ID of the Front Door profile"
  value       = local.frontdoor_profile_id
}

output "cdn_frontdoor_endpoint_id" {
  description = "The ID of the Front Door endpoint"
  value       = azurerm_cdn_frontdoor_endpoint.web_endpoint.id
}

output "custom_domain_validation_token" {
  description = "The validation token for the custom domain"
  value       = azurerm_cdn_frontdoor_custom_domain.custom_domain.validation_token
}

output "cdn_frontdoor_name" {
  description = "The name of the Front Door profile"
  value       = local.frontdoor_profile_name
}
