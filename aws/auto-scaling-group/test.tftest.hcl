// Plan against an empty state without AWS credentials or API calls.
provider "aws" {
  region                      = "eu-central-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

variables {
  name               = "test-asg-idle-timeout"
  ami_id             = "ami-0ba27d9989b7d8c5d" # Amazon Linux 2023 arm64 for eu-central-1
  instance_type      = "t4g.nano"
  availability_zones = ["eu-central-1a", "eu-central-1b"]
}

run "plan_with_default_destination_port" {
  command = plan

  variables {
    name             = "test-asg-default-port"
    desired_capacity = 1
    min_size         = 1
    max_size         = 1
  }

  assert {
    condition     = aws_lb_target_group.tg.port == 80
    error_message = "Target group port should default to 80 when asg_destination_port is not specified"
  }

  assert {
    condition     = var.asg_destination_port == 80
    error_message = "asg_destination_port variable should default to 80"
  }

  assert {
    condition     = aws_lb.lb[0].idle_timeout == 60
    error_message = "Existing callers must retain the ALB's 60-second idle timeout."
  }
}

run "plan_with_custom_destination_port_8080" {
  command = plan

  variables {
    name                 = "test-asg-custom-port-8080"
    desired_capacity     = 1
    min_size             = 1
    max_size             = 1
    asg_destination_port = 8080
    alb_idle_timeout     = 300
  }

  assert {
    condition     = aws_lb_target_group.tg.port == 8080
    error_message = "Target group port should be 8080 when asg_destination_port is set to 8080"
  }

  assert {
    condition     = var.asg_destination_port == 8080
    error_message = "asg_destination_port variable should be 8080"
  }

  assert {
    condition     = aws_lb.lb[0].idle_timeout == 300
    error_message = "The configured ALB idle timeout must reach the load balancer."
  }
}
