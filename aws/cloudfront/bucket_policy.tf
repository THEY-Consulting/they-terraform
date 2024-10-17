resource "aws_s3_bucket_policy" "bucket_policy" {
  count = var.attach_bucket_policy ? 1 : 0

  bucket = data.aws_s3_bucket.source.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid : "AllowCloudFrontServicePrincipal",
        Effect = "Allow"
        Principal = {
          "Service" : "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${var.bucket_name}/*"
        Condition : {
          StringEquals : {
            "AWS:SourceArn" : aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = var.name
  description                       = "Allow ${var.name} to access the bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
