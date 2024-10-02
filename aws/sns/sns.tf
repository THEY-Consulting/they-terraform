resource "aws_sns_topic" "main" {
  name                             = var.name
  fifo_topic                       = var.is_fifo
  content_based_deduplication      = var.content_based_deduplication
  archive_policy                   = var.archive_policy
  policy                           = var.access_policy
  sqs_success_feedback_sample_rate = var.sqs_feedback != null ? var.sqs_feedback.sample_rate_in_percent : null
  sqs_success_feedback_role_arn    = aws_iam_role.sns_feedback_role.arn
  sqs_failure_feedback_role_arn    = aws_iam_role.sns_feedback_role.arn
  kms_master_key_id                = var.kms_master_key_id

  lifecycle {
    precondition {
      condition     = var.is_fifo ? var.is_fifo && endswith(var.name, ".fifo") : true
      error_message = "FIFO topic name must end with .fifo."
    }

    precondition {
      condition     = var.is_fifo ? true : !var.is_fifo && !endswith(var.name, ".fifo")
      error_message = "Non FIFO topic name must not end with .fifo."
    }
  }

  tags = var.tags
}

resource "null_resource" "remove_archive_policy" {
  count = var.archive_policy != null ? 1 : 0

  # We need triggers to be able to access another resource within the local-exec on 'destroy'.
  triggers = {
    topic_arn = aws_sns_topic.main.arn
  }

  # In order to destroy a topic, archive policy needs to be disabled first.
  # Currently not supported https://github.com/hashicorp/terraform-provider-aws/issues/38885
  provisioner "local-exec" {
    command = "aws sns set-topic-attributes --topic-arn \"${self.triggers.topic_arn}\" --attribute-name ArchivePolicy --attribute-value \"{}\""
    when    = destroy
  }

  # Ensures that null resource is run first upon destroy.
  depends_on = [aws_sns_topic.main]
}

resource "aws_iam_role" "sns_feedback_role" {
  name = "SNSFeedbackRole-${var.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Sid    = "AllowLoggingToCloudwatch",
        Principal = {
          Service = "sns.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ],
  })

  tags = var.tags
}


resource "aws_iam_role_policy" "sns_feedback_policy" {
  name = "SNSFeedbackPolicy-${var.name}"
  role = aws_iam_role.sns_feedback_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:PutMetricFilter",
          "logs:PutRetentionPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}



