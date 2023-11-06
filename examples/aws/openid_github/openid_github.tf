# --- RESOURCES / MODULES ---

module "github_action_role" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/openid/github"
  source = "../../../aws/openid/github"

  name = "they-test"
  repo = "THEY-Consulting/they-terraform"
}

# --- OUTPUT ---

output "github_action_role" {
  value = module.github_action_role.role_arn
}
