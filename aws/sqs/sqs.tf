data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_sqs_queue" "dlq" {
  count                     = var.dead_letter_queue_config != null ? 1 : 0
  message_retention_seconds = var.dead_letter_queue_config.message_retention_seconds
  name                      = var.dead_letter_queue_config.name
  sqs_managed_sse_enabled   = true

  content_based_deduplication = var.content_based_deduplication
  fifo_queue                  = var.is_fifo
  max_message_size            = var.max_message_size
  policy                      = <<EOF
  {
    "Version": "2012-10-17",
    "Id": "AllowSQSToWriteToDLQ",
    "Statement": [
      {
        "Sid": "AllowSQSActions",
        "Effect": "Allow",
        "Action": "SQS:*",
        "Resource": "arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:${var.name}"
      }
    ]
  }
  EOF

  lifecycle {
    precondition {
      condition     = var.dead_letter_queue_config.message_retention_seconds > var.message_retention_seconds
      error_message = "Message retention seconds of DLQ must be higher than of connected SQS"
    }
  }
}

resource "aws_sqs_queue" "main" {
  content_based_deduplication = var.content_based_deduplication
  fifo_queue                  = var.is_fifo
  max_message_size            = var.max_message_size
  message_retention_seconds   = var.message_retention_seconds
  name                        = var.name
  policy                      = var.access_policy
  redrive_policy = var.dead_letter_queue_config == null ? "{}" : jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.dead_letter_queue_config.max_receive_count
  })
  sqs_managed_sse_enabled    = true
  visibility_timeout_seconds = var.visibility_timeout_seconds

  lifecycle {
    precondition {
      condition     = var.is_fifo ? var.is_fifo && endswith(var.name, ".fifo") : true
      error_message = "FIFO queue name must end with .fifo."
    }

    precondition {
      condition     = var.is_fifo ? true : !var.is_fifo && !endswith(var.name, ".fifo")
      error_message = "Non FIFO queue name must not end with .fifo."
    }
  }
}

resource "aws_sns_topic_subscription" "main" {
  count     = var.sns_topic_arn_for_subscription == null ? 0 : 1
  topic_arn = var.sns_topic_arn_for_subscription
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.main.arn

  lifecycle {
    ignore_changes = [replay_policy]
  }
}
