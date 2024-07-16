variable "name" {
  description = "Name of project"
  type        = string
}

variable "log_retention" {
  description = "Amount of days for log retention"
  type        = number
  default     = 30
}

variable "location" {
  description = "The Azure region where the resources should be created."
  type        = string
}

variable "container_registry_server" {
  description = "The server URL of the container registry."
  type        = string
}
