# --- RESOURCES / MODULES ---

module "lambda_without_build" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../../../aws/lambda"

  name        = "they-test-api-gateway-simple"
  description = "Test lambda without build step"
  source_dir  = "../packages/lambda-simple"
  runtime     = "nodejs20.x"

  build = {
    enabled = false
  }
}

module "lambda_with_custom_headers" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../../../aws/lambda"

  name        = "they-test-api-gateway-custom-headers"
  description = "Test lambda with custom headers in response"
  source_dir  = "../packages/lambda-response-headers"
  runtime     = "nodejs20.x"

  build = {
    enabled = false
  }
}

# --- OUTPUT ---
