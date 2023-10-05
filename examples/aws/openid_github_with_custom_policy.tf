# --- RESOURCES / MODULES ---

module "github_action_role_with_custom_policy" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/openid/github"
  source = "../../aws/openid/github"

  name = "they-test-with-custom-policy"
  repo = "THEY-Consulting/they-terraform"
  policies = [
    {
      name = "they-test-policy"
      policy = jsonencode({
        Version : "2012-10-17",
        Statement : [
          {
            Effect : "Allow",
            Action : [
              "s3:ListBucket",
            ],
            Resource : [
              "arn:aws:s3:::they-test-bucket",
            ]
          }
        ]
      })
    },
  ]
}

# --- OUTPUT ---

output "github_action_role_with_custom_policy" {
  value = module.github_action_role_with_custom_policy.role_arn
}
