locals {
  topic_name = "they-test-sns.fifo"
}

# ---- DATA ----
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# --- RESOURCES / MODULES ---
module "sns_fifo" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/sns"
  source                      = "../../../aws/sns"
  description                 = "this is a test fifo topic"
  name                        = local.topic_name
  is_fifo                     = true
  content_based_deduplication = false
  archive_policy = jsonencode({
    "MessageRetentionPeriod" : 30
  })
  sqs_feedback = {
    sample_rate_in_percent = 100
  }
  access_policy = jsonencode({
    Version = "2012-10-17",
    Statement : [
      {
        Effect    = "Allow",
        Principal = "*",
        Action : [
          "SNS:Publish",
          "SNS:RemovePermission",
          "SNS:SetTopicAttributes",
          "SNS:DeleteTopic",
          "SNS:ListSubscriptionsByTopic",
          "SNS:GetTopicAttributes",
          "SNS:AddPermission",
          "SNS:Subscribe"
        ],
        Resource = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.topic_name}",
      }
    ]
  })


  tags = {
    Project   = "they-terraform-examples"
    CreatedBy = "terraform"
  }
}

# --- OUTPUT ---
output "arn" {
  value = module.sns_fifo.arn
}

output "topic_name" {
  value = module.sns_fifo.topic_name
}
