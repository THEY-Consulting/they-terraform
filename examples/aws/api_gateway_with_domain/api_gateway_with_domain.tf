# --- DATA ---

data "aws_acm_certificate" "acm_certificate" {
  domain      = "they-code.de"
  statuses    = ["ISSUED"]
  most_recent = true

  provider = aws.acm_region
}

# --- RESOURCES / MODULES ---

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

module "lambda_api_gateway_with_domain" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda/gateway"
  source = "../../../aws/lambda/gateway"

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
    # reusing domains leads to long host resolution delays (approx. 1hr), therefore use a suffix to create unique domains
    domain = "they-test-lambda-${random_string.suffix.id}.they-code.de"
  }
}

# --- OUTPUT ---

output "endpoint_urls_with_domain" {
  value = module.lambda_api_gateway_with_domain.endpoint_urls
}
