# --- RESOURCES / MODULES ---

module "lambda_with_build" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../aws/lambda"

  description = "Test typescript lambda with build step"
  name        = "they-test-build"
  runtime     = "nodejs18.x"
  source_dir  = "packages/lambda-typescript"
}

# --- OUTPUT ---

output "build" {
  value = module.lambda_with_build.build
}
