# --- RESOURCES / MODULES ---

module "lambda_with_build" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../../aws/lambda"

  name        = "they-test-build"
  description = "Test typescript lambda with build step"
  source_dir  = "packages/lambda-typescript"
  runtime     = "nodejs18.x"
}

# --- OUTPUT ---

output "build" {
  value = module.lambda_with_build.build
}
