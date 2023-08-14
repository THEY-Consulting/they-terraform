# --- RESOURCES / MODULES ---

module "lambda_with_custom_headers" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../aws/lambda"

  name        = "they-test-custom-headers"
  description = "Test lambda with custom headers in response"
  source_dir  = "packages/lambda-response-headers"
  runtime     = "nodejs18.x"

  build = {
    enabled = false
  }
}

# --- OUTPUT ---
