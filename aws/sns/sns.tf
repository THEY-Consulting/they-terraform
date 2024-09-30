resource "aws_sns_topic" "main" {
  name                        = var.name
  fifo_topic                  = var.is_fifo
  content_based_deduplication = var.content_based_deduplication
#   archive_policy              = var.archive_policy
  policy                      = var.access_policy
  sqs_success_feedback_sample_rate = var.sqs_feedback != null ? var.sqs_feedback.sample_rate_in_percent : null

  tags = var.tags
}

resource "aws_iam_role" "sns_feedback_role" {
  name = "SNSFeedbackRole-${var.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
    Sid = "allow logging to cloudwatch"
  })

  tags = var.tags
}


resource "aws_iam_role_policy" "sns_feedback_policy" {
  name   = "SNSFeedbackPolicy-${var.name}"
  role   = aws_iam_role.sns_feedback_role.id
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



