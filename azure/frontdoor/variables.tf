variable "resource_group" {
  description = "The resource group where the storage account will be created."
  type = object({
    name     = string
    location = string
  })
}

variable "storage_account" {
  description = "The storage account configuration."
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
