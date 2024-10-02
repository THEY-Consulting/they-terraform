output "arn" {
  value = aws_sns_topic.main.arn
}

output "topic_name" {
  value = aws_sns_topic.main.name
}
