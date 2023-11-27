variable "name" {
  description = "Name of the database."
  type        = string
}

variable "location" {
  description = "The Azure region where the resources should be created."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the resources."
  type        = string
}

variable "server" {
  description = "The database server."
  type = object({
    preexisting_name             = optional(string, null)
    version                      = optional(string, "12.0")
    administrator_login          = optional(string, "AdminUser")
    administrator_login_password = optional(string, null)
    allow_azure_resources        = optional(bool, true)
    allow_all                    = optional(bool, false)
    firewall_rules = optional(list(object({
      name             = string
      start_ip_address = string
      end_ip_address   = string
    })), [])
  })
}

variable "users" {
  description = "The users (with logins) to create in the database."
  type = list(object({
    username = string
    password = string
    roles    = list(string)
  }))
  default = []
}

variable "collation" {
  description = "The collation of the database."
  type        = string
  default     = "SQL_Latin1_General_CP1_CI_AS"
}

variable "sku_name" {
  description = "The sku for the database. For serverless databases, this also sets the maximum capacity."
  type        = string
  default     = "GP_S_Gen5_1" # Serverless, General Purpose, Gen 5, 1 vCore
}

variable "max_size_gb" {
  description = "The maximum size of the database in gigabytes."
  type        = number
  default     = 16
}

variable "min_capacity" {
  description = "The minimum vCore of the database. The maximum is set by the sku tier. Only relevant when using a serverless vCore based database. Set this to 0 otherwise."
  type        = number
  default     = 0.5
}

variable "storage_account_type" {
  description = "The storage account type used to store backups for this database. Possible values are Geo, Local and Zone."
  type        = string
  default     = "Local"
}

variable "auto_pause_delay_in_minutes" {
  description = "Time in minutes after which database is automatically paused. A value of -1 means that automatic pause is disabled."
  type        = number
  default     = 60
}

variable "tags" {
  description = "Tags for the resources."
  type        = map(string)
  default     = {}
}
