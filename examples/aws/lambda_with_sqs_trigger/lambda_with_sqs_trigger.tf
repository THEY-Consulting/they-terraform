# --- DATA ---
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# --- RESOURCES / MODULES ---

# --- SQS Deployment ---
locals {
  queue_name = "they-test-sqs"
}

module "sqs" {
  source                      = "../../../aws/sqs"
  description                 = "this is a test queue"
  name                        = local.queue_name
  is_fifo                     = false
  content_based_deduplication = false
  dead_letter_queue_config = {
    name                      = "DLQ-${local.queue_name}"
    max_receive_count         = 1
    message_retention_seconds = 1209600 # 14 days, must be higher than message_retention_seconds in module
  }
  access_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
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

# --- Lambda Deployment ---
module "lambda_with_sqs_trigger" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../../../aws/lambda"

  name        = "they-test-sqs"
  description = "Test lambda with sqs trigger"
  source_dir  = "../.packages/lambda-typescript"
  runtime     = "nodejs20.x"

  sqs_trigger = {
    arn = module.sqs.arn
  }
}

# --- OUTPUT ---
output "sqs_arn" {
  value = module.sqs.arn
}

output "sqs_queue_name" {
  value = module.sqs.queue_name
}

output "sqs_topic_subscription_arn" {
  value = module.sqs.topic_subscription_arn
}

output "sqs_dlq_arn" {
  value = module.sqs.dlq_arn
}

output "sqs_dlq_queue_name" {
  value = module.sqs.dlq_queue_name
}

output "lambda_function_name" {
  value = module.lambda_with_sqs_trigger.function_name
}
