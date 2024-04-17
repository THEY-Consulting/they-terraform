variable "name" {
  description = "Name of the app"
  type        = string
}

variable "azure_resource_group_name" {
  description = "The Azure resource group"
  type        = string
}

variable "azure_location" {
  description = "The Azure region"
  type        = string
}

variable "azure_identity_name" {
  description = "Name of an existing azure identity, if not provided, a new one will be created"
  type        = string
  default     = null
}

variable "policies" {
  description = "List of additional policies to attach to the app"
  type = list(object({
    name   = string
    policy = string
  }))
  default = []
}

variable "inline" {
  description = "If true, the policies will be created as inline policies. If false, they will be created as managed policies. Changing this will not necessarily remove the old policies correctly, check in the AWS console!"
  type        = bool
  default     = true
}

variable "boundary_policy_arn" {
  description = "ARN of a boundary policy to attach to the app"
  type        = string
  default     = null
}

variable "INSECURE_allowAccountToAssumeRole" {
  description = "Set to true if you want to allow the account to assume the role. This is insecure and should only be used for testing. Do not enable this in production!"
  type        = bool
  default     = false
}
