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
  name = "they-test-s3-bucket-with-policy-${random_string.suffix.id}"
}

module "s3_bucket_with_policy" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/s3-bucket"
  source = "../../../aws/s3-bucket"

  name       = local.name
  versioning = false

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSLogDeliveryAclCheck",
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action   = "s3:GetBucketAcl",
        Resource = "arn:aws:s3:::${local.name}",
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:*"]
          },
          ArnLike = {
            "aws:SourceArn" = ["arn:aws:logs::${data.aws_caller_identity.current.account_id}:*"]
          }
        }
      }
    ]
  })

  prevent_destroy = false # disable protection for testing purposes, don't do this in production
}

# --- OUTPUT ---

output "id" {
  value = module.s3_bucket_with_policy.id
}

output "arn" {
  value = module.s3_bucket_with_policy.arn
}
