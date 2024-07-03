# --- RESOURCES / MODULES ---

module "lambda_with_go_runtime" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../../../aws/lambda"

  name          = "${terraform.workspace}-they-test-lambda-go-build"
  description   = "Test go lambda with build step"
  source_dir    = "./src"
  handler       = "main"
  architectures = ["arm64"]
  # AWS deprecated the Go-specific runtime.
  runtime = "provided.al2"
  build = {
    enabled   = true
    # The AWS runtime requires that the executable be named `bootstrap`.
    command   = "env GOOS=linux GOARCH=arm64 go build -o bootstrap main.go"
    build_dir = "."
  }

}

# --- OUTPUT ---

output "build" {
  value = module.lambda_with_go_runtime.build
}
