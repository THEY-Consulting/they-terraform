resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_func.function_name}"
  retention_in_days = var.cloudwatch.retention_in_days
}
