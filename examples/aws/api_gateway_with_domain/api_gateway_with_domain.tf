# --- DATA ---

# --- RESOURCES / MODULES ---

module "lambda_api_gateway_with_domain" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda/gateway"
  source = "../../../aws/lambda/gateway"

  name = "they-test-api-gateway-with-domain"
  trustStoreUri = "s3://they-test-api-gateway-with-domain-assets/certificates/truststore.pem"
  endpoints = [
    {
      path          = "simple"
      method        = "GET"
      function_arn  = module.lambda_without_build.arn
      function_name = module.lambda_without_build.function_name
    }
  ]

  domain = {
    zone_name       = "they-code.de."
    domain          = "they-test-lambda.they-code.de"
  }
}

# --- OUTPUT ---

output "endpoint_urls_with_domain" {
  value = module.lambda_api_gateway_with_domain.endpoint_urls
}
