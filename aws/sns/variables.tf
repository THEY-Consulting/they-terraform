variable "name" {
  description = "Name of the SNS topic. Must end with '.fifo' for a FIFO(First-In-First-Out) topic." # TODO: perhaps add check with type="fifo"
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
  description = "Enable or disable depucliation based on the message content. If enabled no message deduplication id is no longer required when sending messages to this topic."
  type        = bool
  default     = false
}

variable "archive_policy" {
  description = "JSON representation of the archive policy. Only available for FIFO topics." # TODO: perhaps add check with type="fifo"..?
  type        = string
  default     = null
}

variable "access_policy" {
  description = "JSON representation of the access policy. Defines who is authorized to do what with the topic." # TODO: perhaps default to 'whole account'.. Or just require this.
  type        = string
}

variable "sqs_feedback" {
  description = "These settings configure the logging of message delivery status to CloudWatch Logs. If omitted traffic to SQS won't be logged."
  type = object({
    sample_rate_in_percent = number
  })
  default = null
}

variable "tags" {
  description = "Map of tags to assign to the SNS Topic and related resources."
  type        = map(string)
  default     = {}
}
