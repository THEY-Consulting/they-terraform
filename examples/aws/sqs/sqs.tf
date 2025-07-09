locals {
  queue_name = "they-test-sqs"
}

# ---- DATA ----
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# --- RESOURCES / MODULES ---
module "sqs" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/sqs"
  source                      = "../../../aws/sqs"
  description                 = "this is a test queue"
  name                        = local.queue_name
  is_fifo                     = false
  content_based_deduplication = false
  max_message_size            = 262144 # 256KB
  message_retention_seconds   = 345600 # 4 days
  visibility_timeout_seconds  = 30
  dead_letter_queue_config = {
    name                      = "DLQ-${local.queue_name}"
    max_receive_count         = 1
    message_retention_seconds = 1209600 # 14 days, must be higher than message_retention_seconds in module
    automated_redrive         = true
    redrive_interval_cron     = "cron(0/2 * * * ? *)" # every 2 minutes
  }
  access_policy = jsonencode({ Version = "2012-10-17", Statement = [
    {
      Sid    = "AllowAllSQSActionsToCurrentAccount",
      Effect = "Allow",
      Principal = {
        AWS = data.aws_caller_identity.current.arn
      },
      Action   = ["SQS:*"],
      Resource = "arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.queue_name}"
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
  value = module.sqs.arn
}

output "queue_name" {
  value = module.sqs.queue_name
}

output "topic_subscription_arn" {
  value = module.sqs.topic_subscription_arn
}

output "dlq_arn" {
  value = module.sqs.dlq_arn
}

output "dlq_queue_name" {
  value = module.sqs.dlq_queue_name
}
