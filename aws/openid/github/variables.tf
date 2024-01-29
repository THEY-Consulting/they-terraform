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

variable "boundary_policy" {
  description = "Boundary policy document as a JSON formatted string"
  type        = string
  default     = null
}

variable "s3StateBackend" {
  description = "Set to true if a s3 state backend was setup with the setup-tfstate module (or uses the same naming scheme for the s3 bucket and dynamoDB table). This will set the required s3 and dynamoDB permissions."
  type        = bool
  default     = true
}
