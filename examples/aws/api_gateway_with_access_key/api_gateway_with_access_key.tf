# --- RESOURCES / MODULES ---

module "lambda_api_gateway_with_access_key" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda/gateway"
  source = "../../../aws/lambda/gateway"

  name = "they-test-api-gateway-with-access-key"
  endpoints = [
    {
      path          = "protected"
      method        = "GET"
      function_arn  = module.lambda_without_build.arn
      function_name = module.lambda_without_build.function_name
    },
    {
      path             = "unprotected"
      method           = "GET"
      function_arn     = module.lambda_without_build.arn
      function_name    = module.lambda_without_build.function_name
      api_key_required = false
    }
  ]
  api_key = {
    value = "secret-test-api-gateway-key"
  }
}

# --- OUTPUT ---

output "endpoint_urls_with_access_key" {
  value = module.lambda_api_gateway_with_access_key.endpoint_urls
}
