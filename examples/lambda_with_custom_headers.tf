# --- RESOURCES / MODULES ---

module "lambda_with_custom_headers" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../aws/lambda"

  description = "Test lambda with custom headers in response"
  name        = "they-test-custom-headers"
  runtime     = "nodejs18.x"
  source_dir  = "packages/lambda-response-headers"
  build = {
    enabled = false
  }
}

# --- OUTPUT ---
