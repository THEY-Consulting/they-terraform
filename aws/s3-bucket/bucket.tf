resource "aws_s3_bucket" "bucket" {
  bucket = var.name
}

# We want to be able to enable/disable destroy protection from outside this module.
# Unfortunately lifecycle.prevent_destroy is not supported for modules.
#
# To work around this, we create a null_resource that is only created if var.prevent_destroy is set to true.
# Using a trigger, we have an implicit dependency on the bucket.
# This way, if var.prevent_destroy is set to true, the bucket can not be destroyed.
# See https://github.com/hashicorp/terraform/issues/18367 for more information.
resource "null_resource" "bucket_guardian" {
  count = var.prevent_destroy ? 1 : 0

  triggers = {
    bucket_arn = aws_s3_bucket.bucket.arn
  }

  lifecycle {
    prevent_destroy = true
  }
}
