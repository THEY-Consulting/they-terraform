resource "aws_iam_role" "asg_instance_role" {
  count = length(var.policies) > 0 ? 1 : 0

  name = "${var.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  dynamic "inline_policy" {
    for_each = var.policies
    content {
      name   = "${var.name}-policy-${inline_policy.value.name}"
      policy = inline_policy.value.policy
    }
  }

  permissions_boundary = var.permissions_boundary_arn
}

resource "aws_iam_instance_profile" "instance_profile" {
  count = length(var.policies) > 0 ? 1 : 0

  name = "${var.name}-instance-profile"
  role = aws_iam_role.asg_instance_role[0].name
}
