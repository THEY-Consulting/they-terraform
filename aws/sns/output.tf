output "arn" {
  value = aws_sqs_queue.main.arn
}

output "queue_name" {
  value = aws_sqs_queue.main.queue_name
}

output "dlq_arn" {
  value = aws_sqs_queue.main.dlq_arn
}

output "dlq_queue_name" {
  value = aws_sqs_queue.main.dlq_queue_name
}
