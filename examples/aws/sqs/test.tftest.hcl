run "module:sqs example:sqs apply" {
  command = apply
}

run "module:sqs example:sqs apply with redrive lambda" {
  command = apply

    variables {
    name          = "test-queue-with-redrive"
    description   = "testing they-terraform sqs module with redrive lambda"
    is_fifo       = false
    access_policy = "{}"
    dead_letter_queue_config = {
      name                   = "test-queue-with-redrive-dlq"
      max_receive_count      = 1
      message_retention_seconds = 1209600 # 14 days
      redrive                = true
      redrive_interval_cron  = "cron(0 * * * ? *)" # Every hour
    }
  }

  assert {
    condition     = module.sqs.redrive_lambda_arn != null
    error_message = "Redrive lambda was not created when redrive option was enabled"
  }
}
