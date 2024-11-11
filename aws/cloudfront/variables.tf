variable "name" {
  description = "Name of CloudFront distribution."
  type        = string
}

variable "domain" {
  description = "The domain name for the CloudFront distribution."
  type        = string
}

variable "certificate_arn" {
  description = "The ARN of the certificate to use for HTTPS."
  type        = string
}

variable "attach_domain" {
  description = "Whether to attach the domain to the CloudFront distribution."
  type        = bool
  default     = true
}

variable "bucket_name" {
  description = "The S3 bucket to use as the origin for the CloudFront distribution."
  type        = string
}

variable "attach_bucket_policy" {
  description = "Whether to attach a bucket policy to the S3 bucket."
  type        = bool
  default     = true
}

variable "origin_name" {
  description = "The name of the origin."
  type        = string
  default     = "s3"
}

variable "origin_path" {
  description = "The path within the origin."
  type        = string
  default     = ""
}

variable "cloudfront_routing" {
  description = "The CloudFront routing configuration, valid are `simple` and `branch`"
  type        = string
  default     = "simple"

  validation {
    condition     = contains(["simple", "branch"], var.cloudfront_routing)
    error_message = "The CloudFront routing configuration must be either `simple` or `branch`."
  }
}
