resource "aws_s3_bucket_public_access_block" "default" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  count = var.policy != null ? 1 : 0

  bucket = aws_s3_bucket.bucket.id
  policy = var.policy
}
