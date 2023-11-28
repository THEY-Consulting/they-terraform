resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  count = var.encrypted ? 1 : 0

  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
