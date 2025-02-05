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

variable "INSECURE_allowAccountToAssumeRole" {
  description = "Set to true if you want to allow the account to assume the role. This is insecure and should only be used for testing. Do not enable this in production!"
  type        = bool
  default     = false
}

variable "boundary_policy_arn" {
  description = "ARN of a boundary policy to attach to the app"
  type        = string
  default     = null
}

variable "include_default_policies" {
  description = "Configure the default policies that should be included in the role"
  type = object({
    s3StateBackend                = optional(bool, true)
    stateLockTableRegion          = optional(string, "")
    cloudwatch                    = optional(bool, false)
    cloudfront                    = optional(bool, false)
    cloudfront_source_bucket_arns = optional(list(string), null)
    asg                           = optional(bool, false)
    ami_condition = optional(map(string), {
      "ec2:ImageType" : "machine",
      "ec2:Owner" : "amazon",
    })
    iam                    = optional(bool, false)
    delegated_boundary_arn = optional(string, null)
    instance_key_pair_name = optional(string, "")
    route53                = optional(bool, false)
    host_zone_arn          = optional(string, null)
    route53_records        = optional(list(string), null)
    certificate_arns       = optional(list(string), null)
    dynamodb               = optional(bool, false)
    dynamodb_table_names   = optional(list(string), null)
    ecr                    = optional(bool, false)
    ecr_repository_arns    = optional(list(string), null)
  })
  default = {}

  validation {
    condition     = var.include_default_policies.cloudfront == false || var.include_default_policies.cloudfront_source_bucket_arns != null
    error_message = "`cloudfront_source_bucket_arns` is required if `cloudfront` is true."
  }

  validation {
    condition     = (var.include_default_policies.iam == false && var.include_default_policies.asg == false) || var.include_default_policies.delegated_boundary_arn != null
    error_message = "`delegated_boundary_arn` is required if `iam` or `asg` is true."
  }

  validation {
    condition     = var.include_default_policies.asg == false || var.include_default_policies.instance_key_pair_name != ""
    error_message = "`instance_key_pair_name` is required if `asg` is true."
  }

  validation {
    condition     = var.include_default_policies.route53 == false || var.include_default_policies.host_zone_arn != null
    error_message = "`host_zone_arn` is required if `route53` is true."
  }

  validation {
    condition     = var.include_default_policies.route53 == false || var.include_default_policies.route53_records != null
    error_message = "`route53_records` is required if `route53` is true."
  }

  validation {
    condition     = var.include_default_policies.route53 == false || var.include_default_policies.certificate_arns != null
    error_message = "`certificate_arns` is required if `route53` is true."
  }

  validation {
    condition     = var.include_default_policies.dynamodb == false || var.include_default_policies.dynamodb_table_names != null
    error_message = "`dynamodb_table_names` is required if `dynamodb` is true."
  }

  validation {
    condition     = var.include_default_policies.ecr == false || var.include_default_policies.ecr_repository_arns != null
    error_message = "`ecr_repository_arns` is required if `ecr` is true."
  }
}

variable "s3StateBackend" {
  description = "@Deprecated: use `include_default_policies.s3StateBackend` instead."
  type        = bool
  default     = true
}

variable "stateLockTableRegion" {
  description = "@Deprecated: use `include_default_policies.stateLockTableRegion` instead."
  type        = string
  default     = ""
}
