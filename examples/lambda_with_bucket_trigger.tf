# --- RESOURCES / MODULES ---

module "lambda_with_bucket_trigger" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../aws/lambda"

  description = "Test lambda with bucket trigger"
  name        = "they-test-bucket"
  runtime     = "nodejs18.x"
  source_dir  = "packages/lambda-typescript"

  bucket_trigger = {
    name          = "trigger-they-test-bucket-lambda"
    bucket        = "they-dev"
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "they-test-lambda/"
  }
}

# --- OUTPUT ---
