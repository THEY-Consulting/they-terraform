# --- RESOURCES / MODULES ---

module "lambda_with_cron_trigger" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../../../aws/lambda"

  name        = "they-test-cron"
  description = "Test lambda with cron trigger"
  source_dir  = "../packages/lambda-typescript"
  runtime     = "nodejs20.x"

  cron_trigger = {
    name = "trigger-they-test-cron-lambda"
    # below allows for your cron trigger to run shortly after your test deployment, actual cron will look sth more like: cron(0 9 ? * MON-FRI *)
    schedule = "cron(${tonumber(formatdate("mm", timestamp())) + 1} ${tonumber(formatdate("hh", timestamp()))} ? * MON-FRI *)"
  }
}

# --- OUTPUT ---
