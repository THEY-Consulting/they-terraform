data "aws_default_tags" "current" {}

resource "aws_autoscaling_group" "asg" {
  name                 = var.name
  vpc_zone_identifier  = aws_subnet.instances_subnets[*].id
  desired_capacity     = var.desired_capacity
  min_size             = var.min_size
  max_size             = var.max_size
  target_group_arns    = var.loadbalancer_disabled ? [] : [aws_lb_target_group.tg.arn]
  health_check_type    = var.health_check_type
  termination_policies = ["OldestInstance"]

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = aws_launch_template.launch_template.latest_version
  }

  # AWS Auto Scaling Groups dynamically create and destroy EC2 instances
  # as defined in the ASG's configuration. Because these EC2 instances are created
  # and destroyed by AWS, Terraform does not manage them and is not directly
  # aware of them.
  # As a result, the AWS provider cannot apply your default tags
  # to the EC2 instances managed by your ASG.
  # Therefore we need to manually include the default tags.
  dynamic "tag" {
    for_each = merge(data.aws_default_tags.current.tags, var.tags, {
      Name = var.name
      # Allows enforcing instance_refresh when the launch_template changes. Only
      # works when instance_refresh trigger "tag" is set. A somewhat similar
      # approach/solution was proposed here:
      # https://github.com/hashicorp/terraform-provider-aws/issues/16849#issuecomment-764941664
      LaunchTemplateVersion = aws_launch_template.launch_template.latest_version
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true # Enables propagation of the tag to
      # Amazon EC2 instances launched via this ASG.
    }
  }

  instance_refresh {
    strategy = "Rolling"
    triggers = ["tag"]
  }

}

resource "aws_launch_template" "launch_template" {
  name_prefix   = var.name
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name               = var.key_name

  user_data = var.user_data_file_name != null ? filebase64("${path.root}/${var.user_data_file_name}") : var.user_data

  dynamic "iam_instance_profile" {
    for_each = length(var.policies) > 0 ? [1] : []
    content {
      arn = resource.aws_iam_instance_profile.instance_profile[0].arn
    }
  }

  lifecycle {
    precondition {
      condition     = var.user_data == null || var.user_data_file_name == null
      error_message = "Cannot use user_data and user_data_file_name at the same time"
    }
  }
}
