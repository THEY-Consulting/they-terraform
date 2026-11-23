run "plan_with_required_variables" {
  command = plan

  variables {
    name          = "test-queue"
    description   = "testing they-terraform sqs module"
    is_fifo       = false
    access_policy = "{}"
  }

  assert {
    condition     = length(resource.aws_sqs_queue.dlq) == 0
    error_message = "DLQ was planned to be created altough dead_letter_queue_config was not set"
  }
}

run "plan_with_dead_letter_queue" {
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

  assert {
    condition     = length(resource.aws_sqs_queue.dlq) == 1
    error_message = "DLQ was not planned to be created altough dead_letter_queue_config was set"
  }
}

run "reject_shorter_dead_letter_retention" {
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

run "reject_non_fifo_name_with_fifo_suffix" {
  command = plan

  variables {
    name          = "test-queue.fifo"
    description   = "testing they-terraform sqs module"
    is_fifo       = false
    access_policy = "{}"
  }

  expect_failures = [resource.aws_sqs_queue.main]
}

run "reject_fifo_name_without_fifo_suffix" {
  command = plan

  variables {
    name          = "test-queue"
    description   = "testing they-terraform sqs module"
    is_fifo       = true
    access_policy = "{}"
  }

  expect_failures = [resource.aws_sqs_queue.main]
}

run "plan_with_automated_redrive_enabled" {
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
}

run "plan_with_automated_redrive_disabled" {
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
