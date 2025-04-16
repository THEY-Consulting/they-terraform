run "setup_tests" {
  module {
    source = "./test-setup"
  }
}

run "module:sns plan with required variables" {
  command = plan

  variables {
    name          = "test-topic"
    description   = "testing they-terraform sns module"
    is_fifo       = false
    access_policy = "{}"
  }
}

run "module:sns plan with contradicting name and is_fifo config" {
  command = plan

  variables {
    name          = "test-topic.fifo"
    description   = "testing they-terraform sns module"
    is_fifo       = false
    access_policy = "{}"
  }

  expect_failures = [resource.aws_sns_topic.main]
}

run "module:sns (FIFO) plan with required variables" {
  command = plan

  variables {
    name          = "test-topic.fifo"
    description   = "testing they-terraform sns module"
    is_fifo       = true
    access_policy = "{}"
  }
}

run "module:sns (FIFO) plan with contradicting name and is_fifo config" {
  command = plan

  variables {
    name          = "test-topic"
    description   = "testing they-terraform sns module"
    is_fifo       = true
    access_policy = "{}"
  }

  expect_failures = [resource.aws_sns_topic.main]
}


