# --- RESOURCES / MODULES ---

locals {
  name = "they-test-with-attached-vpc"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/25" # 128 IPs

  tags = {
    Name = local.name
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/28" # 16 IPs

  tags = {
    Name = local.name
  }
}

data "aws_security_group" "default" {
  vpc_id = aws_vpc.main.id
  name   = "default"
}

module "lambda_with_attached_vpc" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/lambda"
  source = "../../../aws/lambda"

  name        = local.name
  description = "Typescript lambda attached to vpc"
  source_dir  = "../packages/lambda-typescript"
  runtime     = "nodejs20.x"
  is_bundle   = true
  vpc_config = {
    subnet_ids         = [aws_subnet.public.id]
    security_group_ids = [data.aws_security_group.default.id]
  }
}

# --- OUTPUT ---

output "build" {
  value = module.lambda_with_attached_vpc.build
}

output "function_name" {
  value = module.lambda_with_attached_vpc.function_name
}
