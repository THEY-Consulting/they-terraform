# --- RESOURCES / MODULES ---

module "lambda_with_cron_trigger" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../aws/lambda"

  description = "Test lambda with cron trigger"
  name        = "they-test-cron"
  runtime     = "nodejs18.x"
  source_dir  = "packages/lambda-typescript"

  cron_trigger = {
    name     = "trigger-they-test-cron-lambda"
    schedule = "cron(0 9 ? * MON-FRI *)"
  }
}

# --- OUTPUT ---
