variable "environment" {
  description = "Environment / stage where the application will be launched."
  type        = string
  default     = "dev"
}

variable "eventhub_namespace_name" {
  description = "Name of the eventhub namespace."
  type        = string
}

variable "handler_name" {
  description = "Name of the logs handler."
  type        = string
}

variable "location" {
  description = "The Azure region where the resources should be created."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the function app."
  type        = string
}

variable "sku" {
  description = "The SKU of the event hubs namespace. This is the pricing tier. Use 'Basic', 'Standard', or 'Premium'."
  type        = string
  default     = "Basic"
}

variable "capacity" {
  description = "The capacity of the event hubs namespace. This is the number of throughput units."
  type        = number
  default     = 1
}

variable "dd_api_key" {
  description = "Datadog API key."
  type        = string
  sensitive   = true
}

variable "dd_site" {
  description = "Datadog site."
  type        = string
  default     = "datadoghq.eu"
}

variable "dd_service" {
  description = "Sets the service name within datadog."
  type        = string
  default     = ""
}

variable "dd_tags" {
  description = "Comma-separated list of tags to send to datadog."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}
