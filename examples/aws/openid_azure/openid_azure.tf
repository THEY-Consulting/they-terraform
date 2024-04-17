# --- RESOURCES / MODULES ---

module "azure_openid" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/openid/azure"
  source = "../../../aws/openid/azure"

  name                      = "they-test"
  azure_location            = "Germany West Central"
  azure_resource_group_name = "they-dev"
}

# --- OUTPUT ---

output "aws_role_arn" {
  value = module.azure_openid.role_arn
}

output "azure_identity_client_id" {
  value = module.azure_openid.identity_client_id
}
