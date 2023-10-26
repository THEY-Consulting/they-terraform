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
    # not required if s3_truststore_uri was set
    # certificate_arn = data.aws_acm_certificate.acm_certificate.arn
    s3_truststore_uri = "s3://they-test-api-gateway-with-domain-assets/certificates/truststore.pem"
    zone_name          = "they-code.de."
    domain             = "they-test-gateway-with-mtls.they-code.de"
  }
}

# --- OUTPUT ---

output "endpoint_urls_with_domain_mtls" {
  value = module.lambda_api_gateway_with_domain_mtls.endpoint_urls
}

