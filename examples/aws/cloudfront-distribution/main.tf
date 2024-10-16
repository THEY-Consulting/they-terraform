# --- RESOURCES / MODULES ---

locals {
  name        = "they-test-cloudfront-distribution-${random_string.suffix.id}"
  domain      = "https://they-test-cloudfront.they-code.de"
  root_domain = join(".", slice(split(".", local.domain), 1, length(split(".", local.domain))))
}

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

data "aws_acm_certificate" "global" {
  domain   = local.root_domain
  statuses = ["ISSUED"]

  provider = aws.acm_region
}

module "s3_bucket" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/s3-bucket"
  source = "../../../aws/s3-bucket"

  name       = local.name
  versioning = false

  prevent_destroy = false # disable protection for testing purposes, don't do this in production
}

module "cloudfront_distribution" {
  #   source = "github.com/THEY-Consulting/they-terraform//aws/cloudfront"
  source = "../../../aws/cloudfront"

  name            = local.name
  domain          = local.domain
  certificate_arn = data.aws_acm_certificate.global.arn
  bucket_name     = module.s3_bucket.id
}

# --- OUTPUT ---

output "arn" {
  value = module.cloudfront_distribution.arn
}

output "domain_name" {
  value = module.cloudfront_distribution.domain_name
}

output "hosted_zone_id" {
  value = module.cloudfront_distribution.hosted_zone_id
}

output "domain" {
  value = local.domain
}
