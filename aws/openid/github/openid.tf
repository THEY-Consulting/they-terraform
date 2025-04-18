data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  stateLockTableRegion = coalesce(var.include_default_policies.stateLockTableRegion, var.stateLockTableRegion, data.aws_region.current.name)

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat(
      [
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

  policies = concat(local.prepared_policies, var.policies)
}

resource "aws_iam_role" "github_oidc_role" {
  name               = "github-action-${var.name}"
  assume_role_policy = local.assume_role_policy

  dynamic "inline_policy" {
    for_each = var.inline ? local.policies : []
    content {
      name   = inline_policy.value.name
      policy = inline_policy.value.policy
    }
  }

  permissions_boundary = var.boundary_policy_arn
}

resource "aws_iam_policy" "policy" {
  count = var.inline == false ? length(local.policies) : 0

  name   = "github-action-${var.name}-${local.policies[count.index].name}"
  policy = local.policies[count.index].policy
}

resource "aws_iam_role_policy_attachment" "github_oidc_role_attachment" {
  count      = length(aws_iam_policy.policy)
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = aws_iam_policy.policy[count.index].arn
}
