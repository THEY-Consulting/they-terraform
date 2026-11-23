run "setup_tests" {
  module {
    source = "./test-setup"
  }
}

run "plan_with_required_variables" {
  command = plan

  variables {
    name          = "test-topic"
    description   = "testing they-terraform sns module"
    is_fifo       = false
    access_policy = "{}"
  }
}

run "reject_non_fifo_name_with_fifo_suffix" {
  command = plan

  variables {
    name          = "test-topic.fifo"
    description   = "testing they-terraform sns module"
    is_fifo       = false
    access_policy = "{}"
  }

  expect_failures = [resource.aws_sns_topic.main]
}

run "plan_fifo_with_required_variables" {
  command = plan

  variables {
    name          = "test-topic.fifo"
    description   = "testing they-terraform sns module"
    is_fifo       = true
    access_policy = "{}"
  }
}

run "reject_fifo_name_without_fifo_suffix" {
  command = plan

  variables {
    name          = "test-topic"
    description   = "testing they-terraform sns module"
    is_fifo       = true
    access_policy = "{}"
  }

  expect_failures = [resource.aws_sns_topic.main]
}


