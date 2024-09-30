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

/* SQS TRIGGER */

// will be the dlq for the sqs with lambda trigger we're setting up
resource "aws_sqs_queue" "dlq" {
  count = var.sqs_trigger != null ? 1 : 0

  name = "${var.sqs_trigger.name}-queue"
}

resource "aws_sqs_queue" "main" {
  count = var.sqs_trigger != null ? 1 : 0

  name                        = var.sqs_trigger.name
  visibility_timeout_seconds  = var.sqs_trigger.visibility_timeout
  message_retention_seconds   = var.sqs_trigger.message_retention
  max_message_size            = var.sqs_trigger.max_message_size
  policy                      = var.sqs_trigger.access_policy
  fifo_queue                  = var.sqs_trigger.fifo
  function_name               = aws_lambda_function.lambda_func.function_name
  sqs_managed_sse_enabled     = true
  redrive_policy              = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.0.arn
    maxReceiveCount     = 4 #ToDo: should this be configurable?
  })
}

resource "aws_sqs_queue_redrive_allow_policy" "dlq_redrive_allow_policy" {
  count = var.sqs_trigger != null ? 1 : 0

  queue_url = aws_sqs_queue.dlq.0.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.dlq.0.arn]
  })
}

