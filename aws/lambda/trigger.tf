/* CRON TRIGGER */

resource "aws_cloudwatch_event_rule" "cw_event_rule" {
  count = var.cron_trigger != null ? 1 : 0

  name                = coalesce(var.cron_trigger.name, "trigger-${var.name}")
  description         = var.cron_trigger.description
  schedule_expression = var.cron_trigger.schedule

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "cw_event_target" {
  count = var.cron_trigger != null ? 1 : 0

  target_id = coalesce(var.cron_trigger.name, "target-${var.name}")
  arn       = aws_lambda_function.lambda_func.arn
  rule      = aws_cloudwatch_event_rule.cw_event_rule.0.name
  input = jsonencode({
    body = var.cron_trigger.input
  })
}

resource "aws_lambda_permission" "cron_trigger_lambda_func_permission" {
  count = var.cron_trigger != null ? 1 : 0

  statement_id  = "allow-execution-${aws_cloudwatch_event_rule.cw_event_rule.0.name}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_func.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cw_event_rule.0.arn
}

/* BUCKET TRIGGER */

data "aws_s3_bucket" "source" {
  count = var.bucket_trigger != null ? 1 : 0

  bucket = var.bucket_trigger.bucket
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  count = var.bucket_trigger != null ? 1 : 0

  bucket = var.bucket_trigger.bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_func.arn
    events              = var.bucket_trigger.events
    filter_prefix       = var.bucket_trigger.filter_prefix
    filter_suffix       = var.bucket_trigger.filter_suffix
  }

  depends_on = [aws_lambda_permission.bucket_trigger_lambda_func_permission]
}

resource "aws_lambda_permission" "bucket_trigger_lambda_func_permission" {
  count = var.bucket_trigger != null ? 1 : 0

  statement_id  = "allow-execution-${var.bucket_trigger.bucket}-${var.bucket_trigger.name}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_func.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.source.0.arn
}
