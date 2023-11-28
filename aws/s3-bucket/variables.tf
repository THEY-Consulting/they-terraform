variable "name" {
  description = "Name of the bucket."
  type        = string
}

variable "policy" {
  description = "Policy of s3 bucket."
  type        = string
  default     = null
}

variable "versioning" {
  description = "Enable versioning of s3 bucket."
  type        = bool
}

variable "encrypted" {
  description = "Enable encryption of s3 bucket."
  type        = bool
}

variable "prevent_destroy" {
  description = "Prevent destroy of s3 bucket."
  type        = bool
  default     = true
}
