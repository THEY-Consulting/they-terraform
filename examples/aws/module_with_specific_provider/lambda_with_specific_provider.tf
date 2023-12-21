# --- RESOURCES / MODULES ---

module "module_with_specifig_provider" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../../../aws/lambda"

  name        = "they-test-module-with-specific-provider"
  description = "Test module with specific provider"
  source_dir  = "../.packages/lambda-typescript"
  runtime     = "nodejs20.x"

  # setting provider explicitly
  providers = {
    aws = aws.specific
  }
}

# --- OUTPUT ---
