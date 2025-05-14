locals {
  workspace = replace(terraform.workspace, "-", "")
  # Determine the full domain name based on the presence of a DNS zone
  full_domain_name = var.dns_zone_name != null ? "${var.subdomain}.${var.dns_zone_name}" : "${var.subdomain}.${var.domain}"
}

resource "azurerm_cdn_frontdoor_profile" "fqdn_profile" {
  count = var.frontdoor_profile == null ? 1 : 0

  name                     = "${terraform.workspace}-profile"
  resource_group_name      = var.resource_group.name
  response_timeout_seconds = 16
  sku_name                 = "Standard_AzureFrontDoor"
}

locals {
  frontdoor_profile_id   = var.frontdoor_profile != null ? var.frontdoor_profile.id : azurerm_cdn_frontdoor_profile.fqdn_profile[0].id
  frontdoor_profile_name = var.frontdoor_profile != null ? var.frontdoor_profile.name : azurerm_cdn_frontdoor_profile.fqdn_profile[0].name
}

resource "azurerm_cdn_frontdoor_endpoint" "web_endpoint" {
  name                     = "${terraform.workspace}-web-endpoint"
  cdn_frontdoor_profile_id = local.frontdoor_profile_id
}

resource "azurerm_cdn_frontdoor_rule_set" "rule_set" {
  name                     = "${local.workspace}caching"
  cdn_frontdoor_profile_id = local.frontdoor_profile_id
}

resource "azurerm_cdn_frontdoor_origin_group" "origin_group_web" {
  name                     = "frontdoor-origin-group-${terraform.workspace}-web"
  cdn_frontdoor_profile_id = local.frontdoor_profile_id

  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 16
    successful_samples_required        = 3
  }
  health_probe {
    interval_in_seconds = 100
    path                = "/index.html"
    protocol            = "Http"
    request_type        = "HEAD"
  }
}

resource "azurerm_cdn_frontdoor_origin" "web_origin" {
  depends_on                     = [var.storage_account]
  name                           = "frontdoor-origin-${terraform.workspace}-web"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.origin_group_web.id
  enabled                        = true
  certificate_name_check_enabled = false
  host_name                      = var.storage_account.primary_web_host
  origin_host_header             = var.storage_account.primary_web_host

  http_port  = 80
  https_port = 443
  priority   = 1
  weight     = 1000
}

resource "azurerm_cdn_frontdoor_rule" "cache_rule" {
  depends_on = [
    azurerm_cdn_frontdoor_origin_group.origin_group_web,
    azurerm_cdn_frontdoor_origin.web_origin
  ]
  name                      = "static"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.rule_set.id
  order                     = 1
  behavior_on_match         = "Stop"


  conditions {
    url_file_extension_condition {
      operator     = "Equal"
      match_values = ["css", "js", "ico", "png", "jpeg", "jpg", ".map"]
    }
  }
  actions {
    route_configuration_override_action {
      compression_enabled           = true
      cache_behavior                = "HonorOrigin"
      query_string_caching_behavior = "IgnoreQueryString"
    }
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "custom_domain" {
  name                     = var.domain
  cdn_frontdoor_profile_id = local.frontdoor_profile_id
  host_name                = local.full_domain_name

  tls {
    certificate_type = "ManagedCertificate"
  }
}

# Create the DNS validation TXT record
resource "azurerm_dns_txt_record" "validation" {
  count               = var.dns_zone_name != null ? 1 : 0
  name                = "_dnsauth.${var.subdomain}"
  resource_group_name = coalesce(var.dns_zone_resource_group, var.resource_group.name)
  zone_name           = var.dns_zone_name
  ttl                 = 3600

  record {
    value = azurerm_cdn_frontdoor_custom_domain.custom_domain.validation_token
  }
}

resource "azurerm_dns_cname_record" "frontdoor" {
  count               = var.dns_zone_name != null ? 1 : 0
  name                = var.subdomain
  resource_group_name = coalesce(var.dns_zone_resource_group, var.resource_group.name)
  zone_name           = var.dns_zone_name
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.web_endpoint.host_name
}

resource "azurerm_cdn_frontdoor_route" "default_route" {
  name                            = "frontdoor-${terraform.workspace}-default-route"
  cdn_frontdoor_endpoint_id       = azurerm_cdn_frontdoor_endpoint.web_endpoint.id
  cdn_frontdoor_origin_group_id   = azurerm_cdn_frontdoor_origin_group.origin_group_web.id
  cdn_frontdoor_origin_ids        = [azurerm_cdn_frontdoor_origin.web_origin.id]
  cdn_frontdoor_rule_set_ids      = [azurerm_cdn_frontdoor_rule_set.rule_set.id]
  enabled                         = true
  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.custom_domain.id]
  forwarding_protocol             = "MatchRequest"
  https_redirect_enabled          = true
  patterns_to_match               = ["/*"]
  supported_protocols             = ["Http", "Https"]
  link_to_default_domain          = false
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "domain_association" {
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.custom_domain.id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.default_route.id]
}
