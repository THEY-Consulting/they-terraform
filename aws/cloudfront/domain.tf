data "aws_region" "current" {}

data "aws_route53_zone" "main" {
  count = var.attach_domain ? 1 : 0
  name  = local.root_domain
}

resource "aws_route53_record" "frontend" {
  count = var.attach_domain ? 1 : 0

  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = local.domain_without_protocol
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}
