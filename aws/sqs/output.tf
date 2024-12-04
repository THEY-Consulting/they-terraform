output "arn" {
  value = aws_sqs_queue.main.arn
}

output "queue_name" {
  value = aws_sqs_queue.main.name
}

output "dlq_arn" {
  value = var.dead_letter_queue_config == null ? null : aws_sqs_queue.dlq[0].arn
}

output "dlq_queue_name" {
  value = var.dead_letter_queue_config == null ? null : aws_sqs_queue.dlq[0].name
}

output "topic_subscription_arn" {
  value = var.sns_topic_arn_for_subscription == null ? null : aws_sns_topic_subscription.main[0].arn
}
