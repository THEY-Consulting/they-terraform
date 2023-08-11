# --- RESOURCES / MODULES ---

module "lambda_api_gateway" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda/gateway"
  source = "../aws/lambda/gateway"

  name = "they-test-api-gateway"
  endpoints = [
    {
      path          = "simple"
      method        = "GET"
      function_arn  = module.lambda_without_build.arn
      function_name = module.lambda_without_build.function_name
    },
    {
      path          = "custom-headers"
      method        = "POST"
      function_arn  = module.lambda_with_custom_headers.arn
      function_name = module.lambda_with_custom_headers.function_name
    },
  ]
}

# --- OUTPUT ---

output "invoke_url" {
  value = module.lambda_api_gateway.invoke_url
}

output "endpoint_urls" {
  value = module.lambda_api_gateway.endpoint_urls
}
