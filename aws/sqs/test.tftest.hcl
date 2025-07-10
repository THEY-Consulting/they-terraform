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

  # TODO: need to assert the plan values with the expected result. This is not working.
  assert {
    condition     = module.sqs.dlq_redrive_lambda_arn != null
    error_message = "Redrive lambda was not created when automated_redrive was set to true"
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
    condition     = module.sqs.dlq_redrive_lambda_arn == null
    error_message = "Redrive lambda was created when automated_redrive was set to false"
  }
}
