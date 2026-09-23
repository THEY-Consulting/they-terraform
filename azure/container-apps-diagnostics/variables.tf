variable "container_app_environment_id" {
  description = "Resource ID of the Azure Container Apps managed environment whose logs are forwarded."
  type        = string
}

variable "eventhub" {
  description = "Event Hub name that receives Container Apps logs."
  type        = string
}

variable "namespace" {
  description = "Event Hub namespace name."
  type        = string
}

variable "namespace_authorization_rule_name" {
  description = "Event Hub namespace authorization rule used by the diagnostic setting."
  type        = string
}

variable "namespace_resource_group_name" {
  description = "Resource group containing the Event Hub namespace. Defaults to the managed environment resource group."
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "Optional Log Analytics workspace ID that also receives the logs."
  type        = string
  default     = null
}

variable "enable_system_logs" {
  description = "Forward ContainerAppSystemLogs in addition to always-enabled ContainerAppConsoleLogs."
  type        = bool
  default     = false
}

variable "name" {
  description = "Diagnostic setting resource name."
  type        = string
  default     = "container-app-environment-logs-to-event-hub"
}
