resource "aws_s3_bucket_versioning" "versioning" {
  count = var.versioning ? 1 : 0

  bucket = aws_s3_bucket.bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}
