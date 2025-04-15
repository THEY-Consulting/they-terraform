resource "azurerm_cdn_frontdoor_profile" "fqdn_profile" {
  name                     = "${terraform.workspace}-profile"
  resource_group_name      = var.resource_group.name
  response_timeout_seconds = 16
  sku_name                 = "Standard_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_endpoint" "web_endpoint" {
  name                     = "${terraform.workspace}-web-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fqdn_profile.id
}

resource "azurerm_cdn_frontdoor_rule_set" "rule_set" {
  name                     = "caching"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fqdn_profile.id
}

resource "azurerm_cdn_frontdoor_origin_group" "origin_group_web" {
  name                     = "web"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fqdn_profile.id

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
  name                           = "web"
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

resource "azurerm_cdn_frontdoor_route" "default_route" {
  name                            = "default"
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

resource "azurerm_cdn_frontdoor_custom_domain" "custom_domain" {
  name                     = var.domain
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fqdn_profile.id
  host_name                = "www.${var.domain}.app"

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "domain_association" {
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.custom_domain.id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.default_route.id]
}
