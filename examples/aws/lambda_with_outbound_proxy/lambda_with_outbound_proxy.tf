# --- RESOURCES / MODULES ---

locals {
  name = "they-test-with-outbound-proxy-${random_string.suffix.id}"
}

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

module "outbound_proxy_vpc" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../../../aws/lambda/outbound-proxy-vpc"

  name = local.name
  # Note: Would replace this with a preexisting whitelisted ip in production code.
  # eip_allocation_id = aws_eip.main.allocation_id
}

module "lambda_with_outbound_proxy" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../../../aws/lambda"

  name        = local.name
  description = "Test lambda with outbound proxy"
  source_dir  = "../packages/lambda-outbound-proxy"
  runtime     = "nodejs20.x"
  vpc_config  = module.outbound_proxy_vpc.vpc_config

  build = {
    enabled = false
  }
}

# --- OUTPUT ---

output "eip_public_ip" {
  value       = module.outbound_proxy_vpc.public_outbound_ip
  description = "The public ip of the eip that gets created for this example. The output of the lambda is expected to use and return this ip."
}

output "outbound_proxy_vpc_config" {
  value = module.outbound_proxy_vpc.vpc_config
}

output "lambda_arn" {
  value = module.lambda_with_outbound_proxy.arn
}

output "lambda_name" {
  value = module.lambda_with_outbound_proxy.function_name
}

