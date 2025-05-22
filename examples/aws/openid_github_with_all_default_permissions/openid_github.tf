# --- RESOURCES / MODULES ---

module "github_action_role_with_all_default_permissions" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/openid/github"
  source = "../../../aws/openid/github"

  name = "they-test-with-all-default-permissions"
  repo = "THEY-Consulting/they-terraform"

  inline = false

  include_default_policies = {
    s3StateBackend                = true
    cloudwatch                    = true
    cloudfront                    = true
    cloudfront_source_bucket_arns = ["arn:aws:s3:::they-test-deployment-bucket"]
    asg                           = true
    iam                           = true
    delegated_boundary_arn        = "arn:aws:iam::123456789012:policy/they-test-boundary"
    instance_key_pair_name        = "test-key"
    route53                       = true
    host_zone_arn                 = "arn:aws:route53:::hostedzone/Z1234567890"
    route53_records               = ["test*.they-code.de", "_test*.they-code.de"]
    certificate_arns              = ["arn:aws:acm:::certificate/1234567890"]
    dynamodb                      = true
    dynamodb_table_names          = ["they-test-table"]
    ecr                           = true
    ecr_repository_arns           = ["arn:aws:ecr:::repository/they-test-repo"]
  }
}

# --- OUTPUT ---

output "github_action_role_with_all_default_permissions" {
  value = module.github_action_role_with_all_default_permissions.role_arn
}
