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
  sensitive = true
}

variable "password" {
  description = "The password for the container registry."
  type        = string
  sensitive = true
}

variable "ip_address_type" {
  description = "The type of IP address that should be used."
  type        = string
  default     = "Public" 
}

variable "os_type" {
  description = "The os type that should be used."
  type        = string
  default     = "Linux" 
}

variable "acr_resource_group" {
  description = "Resource group where the container registry is located."
  type        = string
}

#variable "exposed_port" {
#  description = "The port that should be exposed."
#  type        = number
#}

variable "protocol" {
  description = "The protocol that should be used."
  type        = string
  default = "TCP"
}

variable "tags" {
  description = "Additional tags for container instances."
  type        = map(string)
  default     = {}
}

variable "containers" {
  description = "List of containers to be included in the container group"
  type = list(object({
    name   = string
    image  = string
    cpu    = string
    memory = string
    environment_variables = map(string)
    ports  = object({
      port     = number
      protocol = string
    })
    liveness_probe      = optional(object({
      path                = string
      port                = number
      initial_delay_seconds = number
      period_seconds      = number
      success_threshold   = number
      failure_threshold   = number
    }))
    readiness_probe     = optional(object({
      path                = string
      port                = number
      initial_delay_seconds = number
      period_seconds      = number
      success_threshold   = number
      failure_threshold   = number
    }))
  }))
  default = []
}