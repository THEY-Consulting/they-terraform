data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat([
      {
        Action = "sts:AssumeRoleWithWebIdentity",
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        Condition : {
          StringEquals : {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          }
          StringLike : {
            "token.actions.githubusercontent.com:sub" : "repo:${var.repo}:*"
          },
        }
      },
      ],
      var.INSECURE_allowAccountToAssumeRole ? [
        {
          Action = "sts:AssumeRole",
          Effect = "Allow",
          Principal = {
            AWS = data.aws_caller_identity.current.account_id
          },
        },
      ] : []
    )
  })

  policies = concat(
    var.s3StateBackend ? [
      {
        name = "ReadWriteS3StateBucket"
        policy = jsonencode({
          Version : "2012-10-17",
          Statement : [
            {
              Effect : "Allow",
              Action : [
                "s3:GetObject",
                "s3:ListBucket",
                "s3:PutObject",
                "s3:DeleteObject",
              ],
              Resource : [
                "arn:aws:s3:::${var.name}-tfstate",
                "arn:aws:s3:::${var.name}-tfstate/**"
              ]
            }
          ]
        })
      },
      {
        name = "DynamoDbStateLock"
        policy = jsonencode({
          Version : "2012-10-17",
          Statement : [
            {
              Effect : "Allow",
              Action : [
                "dynamodb:DescribeTable",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:DeleteItem",
              ],
              Resource : [
                "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.name}-tfstate-lock",
              ],
            },
          ]
        })
      }
    ] : [],

    var.policies
  )
}

resource "aws_iam_policy" "permissions_boundary" {
  count = var.boundary_policy != null ? 1 : 0

  name   = "github-action-${var.name}-permissions-boundary"
  policy = var.boundary_policy
}

resource "aws_iam_role" "github_oidc_role" {
  name               = "github-action-${var.name}"
  assume_role_policy = local.assume_role_policy

  dynamic "inline_policy" {
    for_each = local.policies
    content {
      name   = inline_policy.value.name
      policy = inline_policy.value.policy
    }
  }

  permissions_boundary = var.boundary_policy != null ? aws_iam_policy.permissions_boundary[0].arn : null
}
