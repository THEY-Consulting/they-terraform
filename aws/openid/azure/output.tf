output "role_name" {
  value = aws_iam_role.azure_oidc_role.name
}

output "role_arn" {
  value = aws_iam_role.azure_oidc_role.arn
}

output "identity_name" {
  value = data.azurerm_user_assigned_identity.identity.name
}

output "identity_client_id" {
  value = data.azurerm_user_assigned_identity.identity.client_id
}
