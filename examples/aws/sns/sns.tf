locals {
  topic_name = "they-test-sns"
}

# ---- DATA ----
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# --- RESOURCES / MODULES ---
module "sns" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/sns"
  source                      = "../../../aws/sns"
  description                 = "this is a test topic"
  name                        = local.topic_name
  is_fifo                     = false
  content_based_deduplication = false
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
        Resource = "arn:aws:sns:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${local.topic_name}",
        "Condition" : {
          "StringEquals" : {
            "AWS:SourceOwner" : data.aws_caller_identity.current.account_id
          }
        },
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
  value = module.sns.arn
}

output "topic_name" {
  value = module.sns.topic_name
}
