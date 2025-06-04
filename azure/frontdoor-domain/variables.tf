variable "subdomain" {
  description = "The subdomain to use (e.g., 'www' for www.yourdomain.com). If not specified, uses 'www'."
  type        = string
  default     = "www"
}

variable "dns_zone_name" {
  description = "The name of the DNS zone where the CNAME and TXT validation records will be created."
  type        = string
}

variable "resource_group_name" {
  description = "The resource group containing the DNS zone."
  type        = string
}

variable "validation_token" {
  description = "The validation token for the custom domain."
  type        = string
}

variable "frontdoor_host_name" {
  description = "The host name of the Azure Front Door endpoint."
  type        = string
}
