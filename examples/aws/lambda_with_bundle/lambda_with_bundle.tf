# --- RESOURCES / MODULES ---

module "lambda_with_bundle" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../../../aws/lambda"

  name        = "${terraform.workspace}-they-test-with-bundle"
  description = "Test lambda with bundle"
  source_dir  = "../packages/lambda-bundle"
  runtime     = "nodejs18.x"

  is_bundle = true
}

# --- OUTPUT ---
