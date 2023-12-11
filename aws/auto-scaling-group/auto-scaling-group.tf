data "aws_default_tags" "current" {}

resource "aws_autoscaling_group" "asg" {
  name                 = var.name
  vpc_zone_identifier  = aws_subnet.subnets[*].id
  desired_capacity     = var.desired_capacity
  min_size             = var.min_size
  max_size             = var.max_size
  target_group_arns    = [ aws_lb_target_group.tg.arn ]
  enabled_metrics      = var.enabled_metrics
  health_check_type    = "ELB" # Integrates with ALB/ELB.
  termination_policies = ["OldestInstance"]

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = aws_launch_template.launch_template.latest_version
  }

  # TODO: define instace_refresh property.

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
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true # Enables propagation of the tag to
      # Amazon EC2 instances launched via this ASG.
    }
  }

}

# TODO: asg_schedules not required for MVP.

# resource "aws_autoscaling_schedule" "asg-schedule" {
#   scheduled_action_name  = var.name
#   min_size               = var.min_size
#   max_size               = var.max_size
#   desired_capacity       = var.desired_capacity
#   recurrence             = var.recurrence
#   autoscaling_group_name = var.autoscaling_group_name
# }

resource "aws_launch_template" "launch_template" {
  name_prefix = "${terraform.workspace}-${var.name}-asg-template"
  image_id    = var.ami_id
  instance_type = terraform.workspace == "prod" ? var.prod_instance_type : var.dev_instance_type

  vpc_security_group_ids =  [ aws_security_group.sg.id ]

  # TODO: 
  user_data = filebase64("${path.module}/user_data.sh")
}


