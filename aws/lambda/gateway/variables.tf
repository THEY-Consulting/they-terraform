locals {
  use_domain = var.domain == null ? false : true
  use_mtls   = local.use_domain ? (var.domain.s3_truststore_uri == null ? false : true) : false
}

variable "name" {
  description = "The name of the api gateway."
  type        = string
}

variable "description" {
  description = "The description of the api gateway."
  type        = string
  default     = ""
}

variable "stage_name" {
  description = "The stage to use for the api gateway."
  type        = string
  default     = "dev"
}

variable "base_path" {
  description = "The base path to use for the api gateway."
  type        = string
  default     = null
}

variable "endpoints" {
  description = "The endpoints to create for the api gateway."
  type = list(object({
    path             = string
    method           = string
    function_name    = string
    function_arn     = string
    authorization    = optional(string)
    authorizer_id    = optional(string)
    api_key_required = optional(bool)
  }))
}

variable "api_key" {
  description = "The api key configuration to use for the api gateway."
  type = object({
    name                   = optional(string)
    value                  = string
    description            = optional(string)
    enabled                = optional(bool) # defaults to true
    usage_plan_name        = optional(string)
    usage_plan_description = optional(string)
  })
  default = null
}

variable "authorizer" {
  description = "The authorizer configuration to use for the api gateway."
  type = object({
    function_name                  = string
    invoke_arn                     = string
    identity_source                = optional(string)
    type                           = optional(string)
    result_ttl_in_seconds          = optional(number)
    identity_validation_expression = optional(string)
  })
  default = null
}

variable "domain" {
  description = "The domain configuration to use for the api gateway."
  type = object({
    certificate_arn       = optional(string)
    s3_truststore_uri     = optional(string)
    s3_truststore_version = optional(string)
    zone_name             = string
    domain                = string
  })
  default = null

  validation {
    # if domain is set, then we need to run an xor validation for either certificate_arn or s3_truststore_uri to be set
    condition = (var.domain != null ?
      ((var.domain.certificate_arn != null && var.domain.s3_truststore_uri == null) ||
      (var.domain.certificate_arn == null && var.domain.s3_truststore_uri != null)) : true
    )
    error_message = "Either 'certificate_arn' or 's3_truststore_uri' must be set. They cannot both be set or both be null"
  }
}

variable "redeployment_trigger" {
  description = "A unique string to force a redeploy of the api gateway. If not set manually, the module will use the configurations for endpoints, api_key, and authorizer config to decide if a redeployment is necessary."
  type        = string
  default     = null
}
