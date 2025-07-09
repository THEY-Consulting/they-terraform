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

module "redrive_lambda" {
  count  = local.with_redrive ? 1 : 0
  source = "github.com/THEY-Consulting/they-terraform//aws/lambda"

  name        = "redrive-dlq-${var.name}"
  description = "Lambda to redrive messages from DLQ back to main queue"
  runtime     = "nodejs20.x"
  timeout     = 60

  source_dir = "${path.module}/redrive_lambda_source"

  environment = {
    SOURCE_QUEUE_URL = aws_sqs_queue.dlq[0].url
    TARGET_QUEUE_URL = aws_sqs_queue.main.url
  }

  cron_trigger = {
    name     = "redrive-dlq-${var.name}-schedule"
    schedule = var.dead_letter_queue_config.redrive_interval_cron
  }

  additional_policies = [
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage",
            "sqs:GetQueueAttributes"
          ]
          Effect   = "Allow"
          Resource = aws_sqs_queue.dlq[0].arn
        },
        {
          Action = [
            "sqs:SendMessage"
          ]
          Effect   = "Allow"
          Resource = aws_sqs_queue.main.arn
        }
      ]
    })
  ]
}

# Create the redrive lambda source directory and file
resource "local_file" "redrive_lambda_source" {
  count    = local.with_redrive ? 1 : 0
  filename = "${path.module}/redrive_lambda_source/index.js"
  content  = <<EOF
import { SQSClient, ReceiveMessageCommand, DeleteMessageCommand } from "@aws-sdk/client-sqs";
import { SendMessageCommand } from "@aws-sdk/client-sqs";

const sqs = new SQSClient();

export const handler = async (event) => {
  const sourceQueueUrl = process.env.SOURCE_QUEUE_URL;
  const targetQueueUrl = process.env.TARGET_QUEUE_URL;

  console.log(`Starting redrive from ${sourceQueueUrl} to ${targetQueueUrl}`);

  let processedCount = 0;

  try {
    while (true) {
      const receiveParams = {
        QueueUrl: sourceQueueUrl,
        MaxNumberOfMessages: 10,
        WaitTimeSeconds: 1
      };

      const receiveResult = await sqs.send(new ReceiveMessageCommand(receiveParams));

      if (!receiveResult.Messages || receiveResult.Messages.length === 0) {
        console.log('No more messages to process');
        break;
      }

      for (const message of receiveResult.Messages) {
        const sendParams = {
          QueueUrl: targetQueueUrl,
          MessageBody: message.Body,
          MessageAttributes: message.MessageAttributes
        };

        await sqs.send(new SendMessageCommand(sendParams));

        const deleteParams = {
          QueueUrl: sourceQueueUrl,
          ReceiptHandle: message.ReceiptHandle
        };

        await sqs.send(new DeleteMessageCommand(deleteParams));
        processedCount++;
      }
    }

    console.log(`Successfully redrove ${processedCount} messages`);
    return { statusCode: 200, body: JSON.stringify({ processedCount }) };
  } catch (error) {
    console.error('Error redriving messages:', error);
    throw error;
  }
};
EOF
}
