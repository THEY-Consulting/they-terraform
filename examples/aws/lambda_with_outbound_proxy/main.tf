# --- RESOURCES / MODULES ---

locals {
  name = "they-test-with-outbound-proxy-${random_string.suffix.id}"
}

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

module "outbound-proxy-vpc" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../../../aws/lambda/outbound-proxy-vpc"

  name = local.name
  # click yourself an eip in aws and adapt the block accordingly
  eip_allocation_id = "eipalloc-026b048a8dd6ff730"
}

module "lambda_with_outbound_proxy" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../../../aws/lambda"

  name        = local.name
  description = "Test lambda with outbound proxy"
  source_dir  = "../packages/lambda-outbound-proxy"
  runtime     = "nodejs20.x"
  vpc_config  = module.outbound-proxy-vpc.vpc_config

  is_bundle = true
}

# --- OUTPUT ---

output "outbound_proxy_vpc_config" {
  value = module.outbound-proxy-vpc.vpc_config
}

output "lambda_arn" {
  value = module.lambda_with_outbound_proxy.arn
}

output "lambda_function_name" {
  value = module.lambda_with_outbound_proxy.function_name
}

