# --- RESOURCES / MODULES ---

module "lambda_with_cron_trigger" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../../aws/lambda"

  name        = "they-test-cron"
  description = "Test lambda with cron trigger"
  source_dir  = "packages/lambda-typescript"
  runtime     = "nodejs18.x"

  cron_trigger = {
    name     = "trigger-they-test-cron-lambda"
    schedule = "cron(0 9 ? * MON-FRI *)"
  }
}

# --- OUTPUT ---
