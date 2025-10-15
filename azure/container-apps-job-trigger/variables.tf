variable "version_tag" {
  description = "version specified when deployed"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment / stage where the application will be launched."
  type        = string
  default     = "dev"
}

variable "name" {
  description = "Name of the trigger function."
  type        = string
}

variable "subscription_id" {
  description = "The subscription ID to use for the Azure provider"
  type        = string
}

variable "location" {
  description = "The Azure region where the resources should be created."
  type        = string
}

variable "resource_group_name" {
  description = "Name of resource group. Set this variable if you do not want to create a new resource group, but rather use an existing one."
  type        = string
}

variable "target" {
  description = "Target Container App Job to trigger"
  type = object({
    name                         = string
    container_app_environment_id = string
  })
}

variable "sentry_dsn" {
  description = "sentry_dsn needed to connect to Sentry project"
  type        = string
  default     = ""
}

variable "sentry_env" {
  description = "sentry_env needed to set Sentry environment"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags for the resources."
  type        = map(string)
  default     = {}
}
