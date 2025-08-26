variable "name" {
  description = "Name of project, and of the resource group, when a new group is to be created."
  type        = string
}

variable "location" {
  description = "The Azure region where the resources should be created."
  type        = string
}

variable "resource_group_name" {
  description = "Name of resource group. Set this variable if you do not want to create a new resource group, but rather use an existing one."
  type        = string
  default     = null
}

variable "container_app_environment_id" {
  description = "ID of an existing Container App Environment. If not provided, a new environment will be created."
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "The ID of the subnet to deploy the Container Apps Environment into. Required when using a custom VNet."
  type        = string
  default     = null
}

variable "enable_log_analytics" {
  description = "If true, a log analytics workspace will be created."
  type        = bool
  default     = false
}

variable "log_retention" {
  description = "Amount of days for log retention"
  type        = number
  default     = 30
}

variable "sku_log_analytics" {
  description = "The SKU of the log analytics workspace."
  type        = string
  default     = "PerGB2018"
}

variable "workload_profile" {
  type = object({
    name                  = string
    workload_profile_type = string // Possible values include Consumption, D4, D8, D16, D32, E4, E8, E16 and E32
  })
  default = null
}

variable "is_system_assigned" {
  description = "If true, a system-assigned managed identity will be created for the environment."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags for the resources."
  type        = map(string)
  default     = {}
}

variable "acr_integration" {
  description = "Azure Container Registry integration configuration using managed identity"
  type = object({
    registry_id  = string # ACR resource ID for role assignment
    login_server = string # ACR login server URL
  })
  default = null
}

variable "auto_assign_system_identity" {
  description = "Automatically assign system-assigned managed identity to jobs that don't have identity configured"
  type        = bool
  default     = true
}

variable "secrets" {
  type = map(list(object({
    name                = string
    value               = optional(string)
    key_vault_secret_id = optional(string)
    identity            = optional(string)
  })))
  description = "Map of job names to their secrets. Each job can have multiple secrets."
  default     = {}
  sensitive   = true
}

variable "jobs" {
  type = map(object({
    name                  = string
    tags                  = optional(map(string))
    workload_profile_name = optional(string)

    # Job configuration
    replica_timeout     = optional(number, 1800) # 30 minutes default
    replica_retry_limit = optional(number, 0)    # No retries by default

    # Trigger configuration - exactly one must be specified
    # Manual trigger config
    manual_trigger_config = optional(object({
      parallelism              = optional(number, 1)
      replica_completion_count = optional(number, 1)
    }))

    # Schedule trigger config
    schedule_trigger_config = optional(object({
      cron_expression          = string
      parallelism              = optional(number, 1)
      replica_completion_count = optional(number, 1)
    }))

    # Event trigger config
    event_trigger_config = optional(object({
      parallelism              = optional(number, 1)
      replica_completion_count = optional(number, 1)
      scale = object({
        min_executions = optional(number, 0)
        max_executions = optional(number, 10)
        rules = list(object({
          name     = string
          type     = string
          metadata = map(string)
          auth = optional(list(object({
            secret_name       = string
            trigger_parameter = string
          })), [])
        }))
      })
    }))

    # Container template
    template = object({
      containers = set(object({
        name    = string
        image   = string
        cpu     = string
        memory  = string
        command = optional(list(string))
        args    = optional(list(string))
        env = optional(list(object({
          name        = string
          value       = optional(string)
          secret_name = optional(string)
        })))
      }))
    })

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))

    registry = optional(list(object({
      server               = string
      username             = optional(string)
      password_secret_name = optional(string)
      identity             = optional(string)
    })))
  }))
  description = "The container app jobs to deploy."
  nullable    = false

  validation {
    condition = alltrue([
      for job_name, job in var.jobs :
      length([
        for config in [job.manual_trigger_config, job.schedule_trigger_config, job.event_trigger_config] :
        config if config != null
      ]) == 1
    ])
    error_message = "Exactly one trigger configuration must be provided: manual_trigger_config, schedule_trigger_config, or event_trigger_config"
  }

  validation {
    condition = alltrue([
      for job_name, job in var.jobs :
      alltrue([
        for container in job.template.containers :
        container.env == null ? true : alltrue([
          for env_var in container.env :
          (env_var.value != null && env_var.secret_name == null) ||
          (env_var.value == null && env_var.secret_name != null)
        ])
      ])
    ])
    error_message = "Each environment variable must have either 'value' or 'secret_name' specified, but not both."
  }
}
