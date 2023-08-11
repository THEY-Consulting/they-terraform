# --- RESOURCES / MODULES ---

module "authorizer_lambda" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../aws/lambda"

  description = "Test typescript authorizer lambda with build step"
  name        = "they-test-build"
  runtime     = "nodejs18.x"
  source_dir  = "packages/lambda-authorizer"
  environment = {
    AUTH_HASH = base64encode("they:secret-test-authorization-key")
  }
}

module "lambda_api_gateway_with_domain" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda/gateway"
  source = "../aws/lambda/gateway"

  name = "they-test-api-gateway-with-domain"
  endpoints = [
    {
      path          = "simple"
      method        = "GET"
      function_arn  = module.lambda_without_build.arn
      function_name = module.lambda_without_build.function_name
    }
  ]

  domain = {
    certificate_arn = data.aws_acm_certificate.acm_certificate.arn
    zone_name       = "they-code.de."
    domain          = "they-test-lambda.they-code.de"
  }
}
