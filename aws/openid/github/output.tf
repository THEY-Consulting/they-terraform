output "role_name" {
  value = aws_iam_role.github_oidc_role.name
}

output "role_arn" {
  value = aws_iam_role.github_oidc_role.arn
}
