
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.bucket.id

  dynamic "rule" {
    for_each = var.lifecycle_rules

    content {
      id = rule.value.name

      dynamic "expiration" {
        for_each = rule.value.days != null ? [rule.value.days] : []

        content {
          days = expiration.value
        }
      }

      filter {
        and {
          prefix = rule.value.prefix

          # prevent deletion of 0-byte objects like explicitly created folders referenced in Terraform
          # we need to increase to 1 to prevent MalformedXML error while 0 works outside of "and" block
          object_size_greater_than = 1
        }
      }

      noncurrent_version_expiration {
        noncurrent_days           = rule.value.noncurrent_days
        newer_noncurrent_versions = rule.value.noncurrent_versions
      }

      status = "Enabled"
    }
  }
}
