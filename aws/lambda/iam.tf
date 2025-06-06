data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "role" {
  count = var.role_arn == null ? 1 : 0

  name = "tf-${var.name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "cloudwatch-logs"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.name}:*"
      }]
    })
  }

  dynamic "inline_policy" {
    for_each = var.iam_policy
    content {
      name   = inline_policy.value.name
      policy = inline_policy.value.policy
    }
  }

  dynamic "inline_policy" {
    # required to attach to vpc, src: https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html#vpc-permissions
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      name = "attach-to-vpc"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect = "Allow"
          Action = [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface",
            "ec2:AssignPrivateIpAddresses",
            "ec2:UnassignPrivateIpAddresses"
          ]
          Resource = "*"
        }]
      })
    }
  }


  tags = var.tags
}

data "aws_iam_policy_document" "sqs_permissions" {
  count = var.sqs_trigger != null ? 1 : 0

  statement {
    sid       = "AllowSQSPermissions"
    effect    = "Allow"
    resources = ["arn:aws:sqs:*"]

    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
    ]
  }
}

resource "aws_iam_policy" "sqs_permissions" {
  count = var.sqs_trigger != null ? 1 : 0

  name   = "sqs-permissions-${var.name}"
  policy = data.aws_iam_policy_document.sqs_permissions[0].json
}

resource "aws_iam_role_policy_attachment" "sqs_permissions" {
  count = var.sqs_trigger != null ? 1 : 0

  policy_arn = aws_iam_policy.sqs_permissions[0].arn
  role       = aws_iam_role.role[0].name
}


