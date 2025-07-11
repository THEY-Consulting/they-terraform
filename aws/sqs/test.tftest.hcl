run "module:sqs plan with required variables" {
  command = plan

  variables {
    name          = "test-queue"
    description   = "testing they-terraform sqs module"
    is_fifo       = false
    access_policy = "{}"
  }
}

run "module:sqs plan with DLQ(dead letter queue)" {
  command = plan

  variables {
    name          = "test-queue"
    description   = "testing they-terraform sqs module"
    is_fifo       = false
    access_policy = "{}"
    dead_letter_queue_config = {
      name                      = "test-queue-dlq"
      max_receive_count         = 1
      message_retention_seconds = 1209600 # 14 days
    }
  }
}

run "module:sqs plan with message retention misconfiguration throws error" {
  command = plan

  variables {
    name                      = "test-queue"
    description               = "testing they-terraform sqs module"
    is_fifo                   = false
    access_policy             = "{}"
    message_retention_seconds = 345600 # 4 days
    dead_letter_queue_config = {
      name                      = "test-queue-dlq"
      max_receive_count         = 1
      message_retention_seconds = 259200 # 3 days
    }
  }

  expect_failures = [resource.aws_sqs_queue.dlq]
}

run "module:sqs plan with contradicting name and is_fifo config throws error" {
  command = plan

  variables {
    name          = "test-queue.fifo"
    description   = "testing they-terraform sqs module"
    is_fifo       = false
    access_policy = "{}"
  }

  expect_failures = [resource.aws_sqs_queue.main]
}

run "module:sqs (FIFO) plan with contradicting name and is_fifo config throws error" {
  command = plan

  variables {
    name          = "test-queue"
    description   = "testing they-terraform sqs module"
    is_fifo       = true
    access_policy = "{}"
  }

  expect_failures = [resource.aws_sqs_queue.main]
}

run "module:sqs plan with automated redrive enabled" {
  command = plan

  variables {
    name          = "test-queue-with-redrive"
    description   = "testing they-terraform sqs module with automated redrive"
    is_fifo       = false
    access_policy = "{}"
    dead_letter_queue_config = {
      name                      = "test-queue-with-redrive-dlq"
      max_receive_count         = 1
      message_retention_seconds = 1209600 # 14 days
      automated_redrive         = true
    }
  }

  assert {
    condition     = length(module.redrive_lambda) == 1
    error_message = "Redrive lambda was not planned to be created altough automated_redrive is set to true"
  }

  assert {
    condition     = module.redrive_lambda[0].cron_trigger.schedule == "cron(0 2 * * ? *)"
    error_message = "Default redrive_interval_cron was not applied correctly"
  }
}

run "module:sqs plan with automated redrive disabled" {
  command = plan

  variables {
    name          = "test-queue-without-redrive"
    description   = "testing they-terraform sqs module without automated redrive"
    is_fifo       = false
    access_policy = "{}"
    dead_letter_queue_config = {
      name                      = "test-queue-without-redrive-dlq"
      max_receive_count         = 1
      message_retention_seconds = 1209600 # 14 days
      automated_redrive         = false
    }
  }

  assert {
    condition     = length(module.redrive_lambda) == 0
    error_message = "Redrive lambda was planned to be created although automated_redrive set to false"
  }
}

run "module:sqs plan with custom redrive interval cron" {
  command = plan

  variables {
    name          = "test-queue-custom-cron"
    description   = "testing they-terraform sqs module with custom redrive cron"
    is_fifo       = false
    access_policy = "{}"
    dead_letter_queue_config = {
      name                      = "test-queue-custom-cron-dlq"
      max_receive_count         = 1
      message_retention_seconds = 1209600 # 14 days
      automated_redrive         = true
      redrive_interval_cron     = "cron(0 12 * * ? *)" # Custom: daily at 12 PM UTC
    }
  }

  assert {
    condition     = length(module.redrive_lambda) == 1
    error_message = "Redrive lambda module was not planned to be created when automated_redrive was set to true"
  }

  assert {
    condition     = module.redrive_lambda[0].cron_trigger.schedule == "cron(0 12 * * ? *)"
    error_message = "Custom redrive_interval_cron was not applied"
  }
}
