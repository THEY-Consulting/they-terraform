variable "name" {
  description = "Name of the SQS queue. Must end with '.fifo' for a FIFO(First-In-First-Out) queue."
  type        = string
}

variable "description" {
  description = "Description of the SQS queue."
  type        = string
}

variable "is_fifo" {
  description = "Determines queue type. If true will create a FIFO queue, will create a Standard queue if false"
  type        = bool
  default     = true
}

variable "content_based_deduplication" {
  description = "Enables or disables deduplication based on the message content. If enabled no message deduplication id is no longer required when sending messages to this queue."
  type        = bool
  default     = false
}

variable "access_policy" {
  description = "JSON representation of the access policy. Defines who is authorized to do what with the queue."
  type        = string
}

variable "max_message_size" {
  description = "The limit of how many bytes a message can contain before Amazon SQS rejects it."
  type        = number
  default     = null
}

variable "message_retention_seconds" {
  description = "The number of seconds Amazon SQS retains a message. Defaults to 345600 (4 days)"
  type        = number
  default     = 345600
}

variable "visibility_timeout_seconds" {
  description = "How long a message remains invisible to other consumers when consumed by a consumer."
  type        = number
  default     = null
}

variable "dead_letter_queue_config" {
  description = "Configuration for the dead letter queue. If provided, a dead letter queue will be created for you."
  type = object({
    name                      = string
    max_receive_count         = number
    message_retention_seconds = number
  })
  default = null
}

variable "sns_topic_arn_for_subscription" {
  description = "ARN of the SNS topic that the SQS queue will subscribe to."
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to assign to the SQS queue and related resources."
  type        = map(string)
  default     = {}
}
