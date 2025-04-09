resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/${local.lambda_func.function_name}"
  retention_in_days = var.cloudwatch.retention_in_days

  tags = var.tags
}
