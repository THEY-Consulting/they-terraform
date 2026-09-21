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
  default     = "psql"
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

variable "storage_tier" {
  description = "The name of storage performance tier for IOPS of the PostgreSQL Flexible Server"
  type        = string
  default     = null #Possible values are P4, P6, P10, P15,P20, P30,P40, P50,P60, P70 or P80. Default value is dependant on the storage_mb value
}

variable "maintenance_window" {
  description = "Maintenance window for the PostgreSQL server"
  type = object({
    day_of_week  = optional(number) #week starts on a Sunday, i.e. Sunday = 0, Monday = 1. Defaults to 0
    start_hour   = optional(number)
    start_minute = optional(number)
  })
  default = null
}

variable "auto_grow_enabled" {
  description = "Enable auto-grow for storage"
  type        = bool
  default     = false
}

variable "postgres_version" {
  description = "PostgreSQL version to use for initial creation. Note: Version changes after creation are managed outside of Terraform and will be ignored."
  type        = string
  default     = "16"
}

variable "pgsql_server_configurations" {
  description = "List of PostgreSQL server configurations to apply"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
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
  description = "The max storage allowed for the PostgreSQL Flexible Server"
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

# ---------------------------------------------------------------------------
# Backup integrity check
# ---------------------------------------------------------------------------

variable "enable_backup_integrity_check" {
  description = "Enable automatic backup integrity checks via a scheduled Azure Container Apps Job."
  type        = bool
  default     = false
}

variable "backup_integrity_checks" {
  description = "SQL sanity checks to run against the restored database. Each check executes a query and optionally asserts at least one row is returned."
  type = list(object({
    label       = string
    query       = string
    expect_rows = optional(bool, true)
  }))
  default = []
}

variable "backup_integrity_schedule" {
  description = "UTC schedule for the backup integrity job. Supported frequencies are Month, Week, and Day; day_of_month defines the monthly UTC-midnight anchor and day_of_week the weekly one (Monday = 1)."
  nullable    = false
  type = object({
    frequency    = optional(string, "Month")
    interval     = optional(number, 1)
    day_of_month = optional(number, 3)
    day_of_week  = optional(number, 1)
  })
  default = {}

  validation {
    condition     = var.backup_integrity_schedule.day_of_month >= 1 && var.backup_integrity_schedule.day_of_month <= 28
    error_message = "backup_integrity_schedule.day_of_month must be between 1 and 28."
  }

  validation {
    condition     = var.backup_integrity_schedule.day_of_week >= 1 && var.backup_integrity_schedule.day_of_week <= 7
    error_message = "backup_integrity_schedule.day_of_week must be between 1 (Monday) and 7 (Sunday)."
  }

  validation {
    condition     = contains(["Month", "Week", "Day"], var.backup_integrity_schedule.frequency)
    error_message = "backup_integrity_schedule.frequency must be one of Month, Week, or Day."
  }

  validation {
    condition     = var.backup_integrity_schedule.interval >= 1 && var.backup_integrity_schedule.interval == floor(var.backup_integrity_schedule.interval)
    error_message = "backup_integrity_schedule.interval must be a whole number of at least 1."
  }
}

variable "backup_integrity_container_image" {
  description = "Version-pinned OCI image for the backup-integrity job. Update only through the documented image release process."
  type        = string
  default     = "ghcr.io/they-consulting/they-terraform-postgresql-backup-integrity:postgresql-backup-integrity-v1.0.0"

  validation {
    condition     = !can(regex(":latest$", var.backup_integrity_container_image))
    error_message = "backup_integrity_container_image must be version-pinned; the latest tag is not allowed."
  }
}

variable "backup_integrity_replica_timeout_seconds" {
  description = "Maximum job execution time, including restore and cleanup."
  type        = number
  default     = 5400
}

variable "backup_integrity_replica_retry_limit" {
  description = "Number of retries after a failed backup-integrity execution."
  type        = number
  default     = 1
}

variable "backup_integrity_log_retention_days" {
  description = "Retention period for the job Log Analytics workspace."
  type        = number
  default     = 30
}

variable "backup_integrity_alert_action_group_ids" {
  description = "Existing Azure Monitor action group IDs to notify when an integrity check fails."
  type        = list(string)
  default     = []
}
