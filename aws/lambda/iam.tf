resource "aws_iam_role" "role" {
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
