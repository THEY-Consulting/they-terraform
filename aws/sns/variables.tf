variable "name" {
  description = "Name of the SNS topic. Must end with '.fifo' for a FIFO(First-In-First-Out) topic."
  type        = string

}

variable "description" {
  description = "Description of the SNS topic."
  type        = string
}

variable "is_fifo" {
  description = "Determines topic type. If true will create a FIFO topic, will create a Standard topic if false"
  type        = bool
  default     = true
}

variable "content_based_deduplication" {
  description = "Enables or disables deduplication based on the message content. If enabled no message deduplication id is no longer required when sending messages to this topic."
  type        = bool
  default     = false
}

variable "archive_policy" {
  description = "JSON representation of the archive policy. Only available for FIFO topics."
  type        = string
  default     = null
}

variable "access_policy" {
  description = "JSON representation of the access policy. Defines who is authorized to do what with the topic."
  type        = string
}

variable "sqs_feedback" {
  description = "These settings configure the logging of message delivery status to CloudWatch Logs. If omitted traffic to SQS won't be logged."
  type = object({
    sample_rate_in_percent = number
  })
  default = null
}

variable "kms_master_key_id" {
  description = "KMS key id used for encryption."
  type        = string
  # Default alias for AWS managed key. See: https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms
  default = "alias/aws/sns"
}

variable "tags" {
  description = "Map of tags to assign to the SNS Topic and related resources."
  type        = map(string)
  default     = {}
}
