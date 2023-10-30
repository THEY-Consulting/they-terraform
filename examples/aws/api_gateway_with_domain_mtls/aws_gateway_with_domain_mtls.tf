# --- RESOURCES / MODULES ---

module "lambda_api_gateway_with_domain_mtls" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda/gateway"
  source = "../../../aws/lambda/gateway"

  name = "they-test-api-gateway-with-domain_mtls"
  endpoints = [
    {
      path          = "simple"
      method        = "GET"
      function_arn  = module.lambda_without_build.arn
      function_name = module.lambda_without_build.function_name
    }
  ]

  domain = {
    s3_truststore_uri = "s3://they-test-api-gateway-with-domain-assets/certificates/truststore.pem"
    zone_name          = "they-code.de."
    # used domain without timestamp during mtls development, which now delays lambda host resolution (approx. 1hr).
    domain          = "${formatdate("YYYY-MM-YY-hh-mm-ss", timestamp())}-they-test-lambda.they-code.de"
  }
}

# --- OUTPUT ---

output "endpoint_urls_with_domain_mtls" {
  value = module.lambda_api_gateway_with_domain_mtls.endpoint_urls
}

