locals {
  workspace = replace(terraform.workspace, "-", "")
  # Determine the full domain name based on the presence of a DNS zone
  full_domain_name = var.dns_zone_name != null ? "${var.subdomain}.${var.dns_zone_name}" : "${var.subdomain}.${var.domain}"

  is_web_mode = var.web != null
  web_host    = var.web != null ? var.web.primary_web_host : null

  # Backend host configuration
  backend_host        = var.backend != null ? var.backend.host : null
  backend_host_header = var.backend != null ? coalesce(var.backend.host_header, var.backend.host) : null

  input_validation = (
    (var.web != null && var.backend == null) ||
    (var.web == null && var.backend != null)
  )
}

resource "terraform_data" "validate_inputs" {
  lifecycle {
    precondition {
      condition     = local.input_validation
      error_message = "You must provide exactly one of 'web' or 'backend'"
    }
  }
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

  # Origin name based on the type
  origin_name = local.is_web_mode ? "web-origin" : "backend-origin"
}

resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  name                     = "${terraform.workspace}-${var.web != null ? "web" : "backend"}-endpoint"
  cdn_frontdoor_profile_id = local.frontdoor_profile_id
}

resource "azurerm_cdn_frontdoor_rule_set" "rule_set" {
  name                     = "${local.workspace}${var.web != null ? "web" : "backend"}caching"
  cdn_frontdoor_profile_id = local.frontdoor_profile_id
}

resource "azurerm_cdn_frontdoor_origin_group" "origin_group" {
  name                     = "frontdoor-origin-group-${terraform.workspace}-${local.is_web_mode ? "web" : "backend"}"
  cdn_frontdoor_profile_id = local.frontdoor_profile_id

  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 16
    successful_samples_required        = 3
  }

  health_probe {
    interval_in_seconds = local.is_web_mode ? 100 : (var.backend.health_probe.interval)
    path                = local.is_web_mode ? "/index.html" : (var.backend.health_probe.path)
    protocol            = local.is_web_mode ? "Http" : (var.backend.health_probe.protocol)
    request_type        = local.is_web_mode ? "HEAD" : (var.backend.health_probe.request_type)
  }
}

resource "azurerm_cdn_frontdoor_origin" "origin" {
  name                          = "frontdoor-origin-${terraform.workspace}-${local.origin_name}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_group.id
  enabled                       = true
  certificate_name_check_enabled = local.is_web_mode ? true : (
    var.backend != null ? var.backend.certificate_name_check_enabled : false
  )

  # Host settings differ based on mode
  host_name          = local.is_web_mode ? local.web_host : local.backend_host
  origin_host_header = local.is_web_mode ? local.web_host : local.backend_host_header

  http_port  = local.is_web_mode ? 80 : var.backend.http_port
  https_port = local.is_web_mode ? 443 : var.backend.https_port
  priority   = 1
  weight     = 1000
}

# Caching rules for static content (only relevant for web mode)
resource "azurerm_cdn_frontdoor_rule" "cache_rule" {
  count = local.is_web_mode ? 1 : 0

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

# Redirect rules for single page applications (only relevant for web spa mode)
resource "azurerm_cdn_frontdoor_rule" "spa_rewrite" {
  count                     = local.is_web_mode && var.web.is_spa ? 1 : 0
  name                      = "sparewrite"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.rule_set.id
  order                     = 2
  behavior_on_match         = "Continue"

  conditions {
    url_path_condition {
      operator = "Any"
    }
  }

  actions {
    url_rewrite_action {
      source_pattern          = "/"
      destination             = "/index.html"
      preserve_unmatched_path = false
    }
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "custom_domain" {
  name                     = "${var.web != null ? "web" : "backend"}-domain-${terraform.workspace}"
  cdn_frontdoor_profile_id = local.frontdoor_profile_id
  host_name                = local.full_domain_name

  tls {
    certificate_type = "ManagedCertificate"
  }
}

resource "azurerm_cdn_frontdoor_route" "default_route" {
  name                            = "frontdoor-${terraform.workspace}-default-route"
  cdn_frontdoor_endpoint_id       = azurerm_cdn_frontdoor_endpoint.endpoint.id
  cdn_frontdoor_origin_group_id   = azurerm_cdn_frontdoor_origin_group.origin_group.id
  cdn_frontdoor_origin_ids        = [azurerm_cdn_frontdoor_origin.origin.id]
  cdn_frontdoor_rule_set_ids      = [azurerm_cdn_frontdoor_rule_set.rule_set.id]
  enabled                         = true
  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.custom_domain.id]
  forwarding_protocol = local.is_web_mode ? "MatchRequest" : (
    var.backend != null ? var.backend.forwarding_protocol : "HttpOnly"
  )
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]
  link_to_default_domain = false

  dynamic "cache" {
    for_each = local.is_web_mode ? [var.cache_settings] : []
    content {
      query_string_caching_behavior = var.cache_settings.query_string_caching_behavior
      compression_enabled           = var.cache_settings.compression_enabled
      content_types_to_compress     = var.cache_settings.content_types_to_compress
    }
  }
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "domain_association" {
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.custom_domain.id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.default_route.id]
}
