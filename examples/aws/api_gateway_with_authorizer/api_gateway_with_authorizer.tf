# --- RESOURCES / MODULES ---

module "authorizer_lambda" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../../../aws/lambda"

  name        = "they-test-authorizer"
  description = "Test typescript authorizer lambda"
  source_dir  = "../packages/lambda-authorizer"
  runtime     = "nodejs20.x"

  environment = {
    AUTH_HASH = base64encode("they:secret-test-authorization-key"),
  }
}

module "lambda_api_gateway_with_authorizer" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda/gateway"
  source = "../../../aws/lambda/gateway"

  name = "they-test-api-gateway-with-authorizer"
  endpoints = [
    {
      path          = "protected"
      method        = "GET"
      function_arn  = module.lambda_without_build.arn
      function_name = module.lambda_without_build.function_name
    },
    {
      path          = "unprotected"
      method        = "GET"
      function_arn  = module.lambda_without_build.arn
      function_name = module.lambda_without_build.function_name
      authorization = "NONE"
    }
  ]

  authorizer = {
    function_name         = module.authorizer_lambda.function_name
    invoke_arn            = module.authorizer_lambda.invoke_arn
    identity_source       = "method.request.header.Authorization"
    result_ttl_in_seconds = 0
    type                  = "REQUEST"
  }
}

# --- OUTPUT ---

output "endpoint_urls_with_authorizer" {
  value = module.lambda_api_gateway_with_authorizer.endpoint_urls
}
