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

variable "s3StateBackend" {
  description = "Set to true if a s3 state backend was setup with the setup-tfstate module (or uses the same naming scheme for the s3 bucket and dynamoDB table). This will set the required s3 and dynamoDB permissions."
  type        = bool
  default     = true
}

variable "stateLockTableRegion" {
  description = "Region of the state lock table, if different from the default region."
  type        = string
  default     = ""
}

variable "cloudwatch" {
  description = "Set to true if the app uses CloudWatch"
  type        = bool
  default     = false
}

variable "cloudfront" {
  description = "Set to true if the app uses CloudFront"
  type        = bool
  default     = false
}

variable "cloudfront_source_bucket_arns" {
  description = "The ARNs of the S3 buckets that are allowed as CloudFront sources."
  type        = list(string)
  default     = null

  validation {
    condition     = var.cloudfront == false || var.cloudfront_source_bucket_arns != null
    error_message = "`cloudfront_source_bucket_arns` is required if `cloudfront` is true."
  }
}

variable "asg" {
  description = "Set to true if the app uses an Auto Scaling Group"
  type        = bool
  default     = false
}

variable "ami_condition" {
  description = "The condition that must be met by AMIs that are used to launch instances"
  type        = map(string)
  default = {
    "ec2:ImageType" : "machine",
    "ec2:Owner" : "amazon",
  }
}

variable "iam" {
  description = "Set to true if the app uses IAM roles, setting `asg` to true will automatically enable this as well"
  type        = bool
  default     = false
}

variable "delegated_boundary_arn" {
  description = "The ARN of the IAM policy that is used as the permissions boundary for newly created roles"
  type        = string
  default     = null

  validation {
    condition     = (var.iam == false && var.asg == false) || var.delegated_boundary_arn != null
    error_message = "`delegated_boundary_arn` is required if `iam` or `asg` is true."
  }
}

variable "instance_key_pair_name" {
  description = "The name of the key pair that is used to launch instances"
  type        = string
  default     = ""

  validation {
    condition     = var.asg == false || var.instance_key_pair_name != ""
    error_message = "`instance_key_pair_name` is required if `asg` is true."
  }
}

variable "route53" {
  description = "Set to true if the app uses Route 53"
  type        = bool
  default     = false
}

variable "host_zone_arn" {
  description = "The ARN of the Route 53 Hosted Zone that is used for the domain"
  type        = string
  default     = null

  validation {
    condition     = var.route53 == false || var.host_zone_arn != null
    error_message = "`host_zone_arn` is required if `route53` is true."
  }
}

variable "route53_records" {
  description = "The Route 53 records that are allowed to be created, supports wildcards"
  type        = list(string)
  default     = null

  validation {
    condition     = var.route53 == false || var.route53_records != null
    error_message = "`route53_records` is required if `route53` is true."
  }
}

variable "certificate_arns" {
  description = "The ARNs of the ACM certificates that are allowed to be used"
  type        = list(string)
  default     = null

  validation {
    condition     = var.route53 == false || var.certificate_arns != null
    error_message = "`certificate_arns` is required if `route53` is true."
  }
}

variable "dynamodb" {
  description = "Set to true if the app uses DynamoDB"
  type        = bool
  default     = false
}

variable "dynamodb_table_names" {
  description = "The Names of DynamoDB tables that are allowed to be managed"
  type        = list(string)
  default     = null

  validation {
    condition     = var.dynamodb == false || var.dynamodb_table_names != null
    error_message = "`dynamodb_table_names` is required if `dynamodb` is true."
  }
}

variable "ecr" {
  description = "Set to true if the app uses ECR"
  type        = bool
  default     = false
}

variable "ecr_repository_arns" {
  description = "The ARNs of the ECR repositories that are allowed to be accessed"
  type        = list(string)
  default     = null

  validation {
    condition     = var.ecr == false || var.ecr_repository_arns != null
    error_message = "`ecr_repository_arns` is required if `ecr` is true."
  }
}
