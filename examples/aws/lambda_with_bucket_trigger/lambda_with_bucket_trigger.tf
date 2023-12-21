# --- RESOURCES / MODULES ---

module "lambda_with_bucket_trigger" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../../../aws/lambda"

  name        = "they-test-bucket"
  description = "Test lambda with bucket trigger"
  source_dir  = "../.packages/lambda-typescript"
  runtime     = "nodejs20.x"

  bucket_trigger = {
    name          = "trigger-they-test-bucket-lambda"
    bucket        = "they-dev"
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "they-test-lambda/"
  }
}

# --- OUTPUT ---
