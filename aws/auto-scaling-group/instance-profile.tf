resource "aws_iam_role" "asg_instance_role" {
  count = length(var.policies) > 0 ? 1 : 0

  name = var.name

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

  permissions_boundary = var.permissions_boundary_arn
}

resource "aws_iam_role_policy" "instance_policy" {
  count = length(var.policies)

  name   = "${var.name}-${var.policies[count.index].name}"
  role   = aws_iam_role.asg_instance_role[0].name
  policy = var.policies[count.index].policy
}

resource "aws_iam_role_policies_exclusive" "example" {
  count = length(var.policies) > 0 ? 1 : 0

  role_name    = aws_iam_role.asg_instance_role[0].name
  policy_names = aws_iam_role_policy.instance_policy[*].name
}

resource "aws_iam_instance_profile" "instance_profile" {
  count = length(var.policies) > 0 ? 1 : 0

  name = var.name
  role = aws_iam_role.asg_instance_role[0].name
}
