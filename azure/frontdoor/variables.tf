variable "resource_group" {
  description = "The resource group where the resources will be created."
  type = object({
    name     = string
    location = string
  })
}

variable "web" {
  description = "Configuration for web/frontend usage with storage account. Use this for static website hosting."
  type = object({
    primary_web_host = string
    is_spa = optional(bool, false)
  })
  default = null
}

variable "backend" {
  description = "Configuration for backend API services."
  type = object({
    host                           = string
    host_header                    = optional(string)
    http_port                      = optional(number, 80)
    https_port                     = optional(number, 443)
    certificate_name_check_enabled = optional(bool, false)
    forwarding_protocol            = optional(string, "HttpOnly")
    health_probe = optional(object({
      path         = optional(string, "/")
      interval     = optional(number, 120)
      protocol     = optional(string, "Http")
      request_type = optional(string, "GET")
    }), {})
  })
  default = null
}

variable "domain" {
  description = "The base domain name (without the subdomain part)."
  type        = string
}

variable "subdomain" {
  description = "The subdomain to use (e.g., 'www' for www.yourdomain.com). If not specified, uses 'www'."
  type        = string
  default     = "www"
}

variable "dns_zone_name" {
  description = "The name of the DNS zone where the CNAME and TXT validation records will be created."
  type        = string
  default     = null
}

variable "dns_zone_resource_group" {
  description = "The resource group containing the DNS zone. If not specified, uses the same resource group as the Front Door."
  type        = string
  default     = null
}

variable "is_external_dns_zone" {
  description = "Set to true if the domain is managed outside of the Azure account (e.g., in AWS Route 53 or in another Azure account). If true, DNS records will not be created."
  type        = bool
  default     = false
}

variable "frontdoor_profile" {
  description = "Existing Front Door profile to use instead of creating a new one. If not provided, a new profile will be created."
  type = object({
    id   = string
    name = string
  })
  default = null
}

variable "cache_settings" {
  description = "Cache settings for the Front Door."
  type = object({
    query_string_caching_behavior = optional(string, "IgnoreQueryString")
    compression_enabled           = optional(bool, true)
    content_types_to_compress     = optional(list(string), ["application/json", "text/plain", "text/css", "application/javascript"])
  })
  default = {}
}
