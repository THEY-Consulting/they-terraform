# --- RESOURCES / MODULES ---

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

data "aws_s3_object" "truststore" {
  bucket = "they-test-api-gateway-with-domain-assets"
  key    = "certificates/truststore.pem"
}

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
    s3_truststore_uri     = "s3://they-test-api-gateway-with-domain-assets/certificates/truststore.pem"
    s3_truststore_version = data.aws_s3_object.truststore.version_id
    zone_name             = "they-code.de."
    # reusing domains leads to long host resolution delays (approx. 1hr), therefore use a suffix to create unique domains
    domain = "they-test-api-gateway-with-domain-mtls-${random_string.suffix.id}.they-code.de"
  }
}

# --- OUTPUT ---

output "endpoint_urls_with_domain_mtls" {
  value = module.lambda_api_gateway_with_domain_mtls.endpoint_urls
}
