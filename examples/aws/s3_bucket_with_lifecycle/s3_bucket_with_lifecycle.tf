# --- DATA ---

data "aws_caller_identity" "current" {}

# --- RESOURCES / MODULES ---

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

locals {
  # bucket names are blocked for some time (approx. 1hr) after destroy, therefore use a random suffix to create unique names
  name = "they-test-s3-bucket-with-lifecycle-${random_string.suffix.id}"
}

module "s3_bucket_with_lifecycle" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/s3-bucket"
  source = "../../../aws/s3-bucket"

  name       = local.name
  versioning = false

  lifecycle_rules = [
    {
      name                = "delete-after-30-days"
      prefix              = "consulting"
      days                = 30
      noncurrent_days     = 1
      noncurrent_versions = 10
    }
  ]

  prevent_destroy = false # disable protection for testing purposes, don't do this in production
}

# --- OUTPUT ---

output "id" {
  value = module.s3_bucket_with_lifecycle.id
}

output "arn" {
  value = module.s3_bucket_with_lifecycle.arn
}
