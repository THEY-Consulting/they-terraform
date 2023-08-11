# --- RESOURCES / MODULES ---

module "lambda_without_build" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../aws/lambda"

  description = "Test lambda without build step"
  name        = "they-test-no-build"
  runtime     = "nodejs18.x"
  source_dir  = "packages/lambda-simple"
  build = {
    enabled = false
  }
}

# --- OUTPUT ---

output "lambda_arn" {
  value = module.lambda_without_build.arn
}

output "archive_file_path" {
  value = module.lambda_without_build.archive_file_path
}
