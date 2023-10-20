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
    zone_name       = string
    domain          = string
  })
  default = null
}

variable "redeployment_trigger" {
  description = "A unique string to force a redeploy of the api gateway. If not set manually, the module will use the configurations for endpoints, api_key, and authorizer config to decide if a redeployment is necessary."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for the resources."
  type        = map(string)
  default     = {}
}
