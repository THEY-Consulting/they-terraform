# --- RESOURCES / MODULES ---

module "lambda_with_diagnostics" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../../../aws/lambda"

  name        = "they-test-diagnostics"
  description = "Test lambda with diagnostics"
  source_dir  = "../.packages/lambda-simple"
  runtime     = "nodejs20.x"

  build = {
    enabled = false
  }

  dd_api_key = var.dd_api_key
  dd_service = "they-terraform-examples"
}

# --- OUTPUT ---

output "lambda_arn" {
  value = module.lambda_with_diagnostics.arn
}
