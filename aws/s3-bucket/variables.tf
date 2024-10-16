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

variable "prevent_destroy" {
  description = "Prevent destroy of s3 bucket."
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "List of rules as objects with lifetime (in days) of the S3 objects that are subject to the policy and path prefix. The number must be a non-zero positive integer."
  type = list(object({
    name                = string,
    prefix              = optional(string, ""),
    days                = optional(number),
    noncurrent_days     = optional(number),
    noncurrent_versions = optional(number)
  }))
  default = []
}
