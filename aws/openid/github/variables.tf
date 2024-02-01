variable "name" {
  description = "Name of the app"
  type        = string
}

variable "repo" {
  description = "Git repo of the app"
  type        = string
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

variable "s3StateBackend" {
  description = "Set to true if a s3 state backend was setup with the setup-tfstate module (or uses the same naming scheme for the s3 bucket and dynamoDB table). This will set the required s3 and dynamoDB permissions."
  type        = bool
  default     = true
}

variable "INSECURE_allowAccountToAssumeRole" {
  description = "Set to true if you want to allow the account to assume the role. This is insecure and should only be used for testing. Do not enable this in production!"
  type        = bool
  default     = false
}
