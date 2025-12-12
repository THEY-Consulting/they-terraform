run "module:auto-scaling-group plan with default destination port" {
  command = plan

  variables {
    name               = "test-asg-default-port"
    ami_id             = "ami-0ba27d9989b7d8c5d" # Amazon Linux 2023 arm64 for eu-central-1
    instance_type      = "t4g.nano"
    desired_capacity   = 1
    min_size           = 1
    max_size           = 1
    availability_zones = ["eu-central-1a", "eu-central-1b"]
  }

  assert {
    condition     = aws_lb_target_group.tg.port == 80
    error_message = "Target group port should default to 80 when asg_destination_port is not specified"
  }

  assert {
    condition     = var.asg_destination_port == 80
    error_message = "asg_destination_port variable should default to 80"
  }
}

run "module:auto-scaling-group plan with custom destination port 8080" {
  command = plan

  variables {
    name                 = "test-asg-custom-port-8080"
    ami_id               = "ami-0ba27d9989b7d8c5d" # Amazon Linux 2023 arm64 for eu-central-1
    instance_type        = "t4g.nano"
    desired_capacity     = 1
    min_size             = 1
    max_size             = 1
    availability_zones   = ["eu-central-1a", "eu-central-1b"]
    asg_destination_port = 8080
  }

  assert {
    condition     = aws_lb_target_group.tg.port == 8080
    error_message = "Target group port should be 8080 when asg_destination_port is set to 8080"
  }

  assert {
    condition     = var.asg_destination_port == 8080
    error_message = "asg_destination_port variable should be 8080"
  }
}
