data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat(
      [
        {
          Action = "sts:AssumeRoleWithWebIdentity",
          Effect = "Allow",
          Principal = {
            Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/sts.windows.net/${data.azurerm_user_assigned_identity.identity.tenant_id}/"
          },
          Condition = {
            StringEquals = {
              "sts.windows.net/${data.azurerm_user_assigned_identity.identity.tenant_id}/:sub" : data.azurerm_user_assigned_identity.identity.principal_id,
              "sts.windows.net/${data.azurerm_user_assigned_identity.identity.tenant_id}/:aud" : data.azurerm_user_assigned_identity.identity.client_id
            }
          }
        }
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
}

resource "aws_iam_role" "azure_oidc_role" {
  name               = "azure-${var.name}"
  assume_role_policy = local.assume_role_policy

  dynamic "inline_policy" {
    for_each = var.inline ? var.policies : []
    content {
      name   = inline_policy.value.name
      policy = inline_policy.value.policy
    }
  }

  permissions_boundary = var.boundary_policy_arn
}

resource "aws_iam_policy" "policy" {
  count = var.inline == false ? length(var.policies) : 0

  name   = "github-action-${var.name}-${var.policies[count.index].name}"
  policy = var.policies[count.index].policy
}

resource "aws_iam_role_policy_attachment" "azure_oidc_role_attachment" {
  count      = length(aws_iam_policy.policy)
  role       = aws_iam_role.azure_oidc_role.name
  policy_arn = aws_iam_policy.policy[count.index].arn
}
