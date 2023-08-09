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

  tags = {
    Name = var.name
  }
}
