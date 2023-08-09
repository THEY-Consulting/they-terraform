variable "name" {
  description = "Name of the lambda function."
  type        = string
}

variable "description" {
  description = "Description of the lambda function."
  type        = string
}

variable "source_dir" {
  description = "Directory containing the lambda function."
  type        = string
}

variable "build" {
  description = "Build configuration."
  type = object({
    enabled   = bool
    command   = optional(string)
    build_dir = optional(string)
  })
  default = {
    enabled   = true
    command   = "yarn run --top-level build"
    build_dir = "dist"
  }
}

variable "cloudwatch" {
  description = "CloudWatch configuration."
  type = object({
    retention_in_days = optional(number)
  })
  default = {
    retention_in_days = 30
  }
}

variable "archive" {
  description = "Archive configuration."
  type = object({
    output_path = optional(string)
    excludes    = optional(list(string))
  })
  default = {
    output_path = null
    excludes    = []
  }
}

variable "role_arn" {
  description = "ARN of the role used for executing the lambda function."
  type        = string
  default     = null
}

variable "iam_policy" {
  description = "IAM policy document to attach to the lambda function."
  type = list(object({
    name   = string
    policy = string
  }))
  default = []
}

variable "handler" {
  description = "Function entrypoint."
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "The runtime that the function is executed with, e.g. 'nodejs18.x'."
  type        = string
}

variable "architectures" {
  description = "The instruction set architecture that the function supports."
  type        = list(string)
  default     = ["arm64"]
}

variable "environment" {
  description = "Map of environment variables that are accessible from the function code during execution."
  type        = map(string)
  default     = null
}

variable "vpc_config" {
  description = "For network connectivity to AWS resources in a VPC, specify a list of security groups and subnets in the VPC. When you connect a function to a VPC, it can only access resources and the internet through that VPC."
  type = object({
    security_group_ids = list(string)
    subnet_ids         = list(string)
  })
  default = null
}

variable "publish" {
  description = "Whether to publish creation/change as new Lambda Function Version."
  type        = bool
  default     = true
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda Function can use at runtime."
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Amount of time your Lambda Function has to run in seconds."
  type        = number
  default     = 3
}

variable "layers" {
  description = "List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function."
  type        = list(string)
  default     = []
}
