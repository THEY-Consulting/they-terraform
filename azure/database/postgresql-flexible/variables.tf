variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}


variable "location" {
  description = "Azure region"
  type        = string
}

variable "server_name" {
  description = "Name of the PostgreSQL server"
  type        = string
}


variable "enable_public_network_access" {
  description = "Enable public network access for the PostgreSQL server"
  type        = bool
  default     = true
}

variable "admin_username" {
  description = "Administrator username"
  type        = string
  default     = "psqladmin"
}

variable "admin_password" {
  description = "Administrator password"
  type        = string
  sensitive   = true

}

variable "sku_name" {
  description = "SKU name for the server"
  type        = string
  default     = "B_Standard_B1ms" # Burstable, the smallest SKU 
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "16"
}

variable "zone" {
  description = "Specify the Availability Zone for the PostgreSQL Flexible server."
  type        = number
  default     = null
}

variable "high_availability" {
  description = "Object of high availability configuration."
  type = object({
    mode                      = string #Possible value are "SameZone" or "ZoneRedundant".
    standby_availability_zone = optional(number)
  })
  default = null
}

variable "storage_mb" {
  description = "Storage size in MB"
  type        = number
  default     = 32768
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "allow_azure_services" {
  description = "Allow Azure services to access the PostgreSQL server"
  type        = bool
  default     = true
}

variable "allow_all" {
  description = "Allow all IP addresses to access the PostgreSQL server"
  type        = bool
  default     = false

}

variable "allowed_ip_ranges" {
  description = "List of allowed IP ranges for firewall rules"
  type = list(object({
    name             = string
    start_ip_address = string
    end_ip_address   = string
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to the resources"
  type        = map(string)
  default     = {}
}

variable "database_name" {
  description = "Name of the PostgreSQL database to create"
  type        = string
  default     = null
}
variable "collation" {
  description = "Collation for the PostgreSQL database"
  type        = string
  default     = "en_US.utf8"
}

variable "charset" {
  description = "Character set for the PostgreSQL database"
  type        = string
  default     = "UTF8"
}

