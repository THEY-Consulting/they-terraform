variable "name" {
  description = "Name of the trigger function."
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

variable "target_container_app_job_id" {
  description = "Target Container App Job to trigger"
  type        = string
}

variable "tags" {
  description = "Tags for the resources."
  type        = map(string)
  default     = {}
}
