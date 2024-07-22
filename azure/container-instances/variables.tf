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

variable "username" {
  description = "The username for the container registry."
  type        = string
}

variable "password" {
  description = "The password for the container registry."
  type        = string
}

variable "environment_variables_backend" {
  description = "Environment variables for the container."
  type        = map(string)
  default     = {}
}

variable "environment_variables_frontend" {
  description = "Environment variables for the container."
  type        = map(string)
  default     = {}
}