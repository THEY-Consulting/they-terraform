# --- RESOURCES / MODULES ---

module "lambda_without_build" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../../../aws/lambda"

  name        = "they-test-api-gateway-with-access-key-simple"
  description = "Test lambda without build step"
  source_dir  = "../packages/lambda-simple"
  runtime     = "nodejs18.x"

  build = {
    enabled = false
  }
}

# --- OUTPUT ---
