# --- RESOURCES / MODULES ---

locals {
  api_key = "secret-test-api-gateway-key"
}

module "lambda_api_gateway_with_access_key" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda/gateway"
  source = "../../../aws/lambda/gateway"

  name = "${terraform.workspace}-they-test-api-gateway-with-access-key"
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
    value = local.api_key
  }
}

resource "checkmate_http_health" "endpoint_with_key" {
  url    = module.lambda_api_gateway_with_access_key.endpoint_urls[0]
  method = "GET"
  headers = {
    X-Api-Key = local.api_key
  }
  status_code = 200
  timeout     = 30000

  depends_on = [module.lambda_api_gateway_with_access_key]
}

check "can_access_endpoint" {
  assert {
    condition     = checkmate_http_health.endpoint_with_key.passed
    error_message = "Endpoint responded with wrong HTTP status"
  }
}

check "api_key_required" {
  data "http" "endpoint_without_key" {
    url    = module.lambda_api_gateway_with_access_key.endpoint_urls[0]
    method = "GET"
  }

  assert {
    condition     = data.http.endpoint_without_key.status_code == 403
    error_message = "Endpoint responded with HTTP status ${data.http.endpoint_without_key.status_code}"
  }
}

# --- OUTPUT ---

output "endpoint_urls_with_access_key" {
  value = module.lambda_api_gateway_with_access_key.endpoint_urls
}
