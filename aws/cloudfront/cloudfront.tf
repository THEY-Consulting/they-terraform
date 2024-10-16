locals {
  root_domain             = join(".", slice(split(".", var.domain), 1, length(split(".", var.domain))))
  domain_without_protocol = replace(var.domain, "https://", "")
}

data "aws_s3_bucket" "source" {
  bucket = var.bucket_name
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_function" "routing" {
  name    = "${var.name}-routing"
  runtime = "cloudfront-js-2.0"
  comment = "Redirects all requests to index.html that are not requesting a file"
  publish = true
  code    = file("${path.module}/routing/${var.cloudfront_routing}.js")
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.name
  default_root_object = "index.html"
  price_class         = "PriceClass_100" // US, Canada, Europe
  http_version        = "http2"

  aliases = [local.domain_without_protocol]

  origin {
    origin_id                = var.origin_name
    origin_path              = var.origin_path
    domain_name              = data.aws_s3_bucket.source.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    target_origin_id       = var.origin_name
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.routing.arn
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  # TODO: do we need this?
  #  logging_config {
  #    include_cookies = false
  #    bucket          = "mylogs.s3.amazonaws.com"
  #    prefix          = "myprefix"
  #  }
}
