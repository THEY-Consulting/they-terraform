# --- RESOURCES / MODULES ---

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

module "s3_bucket" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/s3-bucket"
  source = "../../../aws/s3-bucket"

  # bucket names are blocked for some time (approx. 1hr) after destroy, therefore use a random suffix to create unique names
  name       = "they-test-s3-bucket-${random_string.suffix.id}"
  encrypted  = true
  versioning = true

  prevent_destroy = false # disable protection for testing purposes, don't do this in production
}

# --- OUTPUT ---

output "id" {
  value = module.s3_bucket.id
}

output "arn" {
  value = module.s3_bucket.arn
}

output "versioning" {
  value = module.s3_bucket.versioning
}
