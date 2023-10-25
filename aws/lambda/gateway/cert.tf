locals {
  use_mtls = var.domain == null ? false : var.domain.s3_trust_store_uri == null ? false : true
}

# only used when we use mtls
resource "aws_acm_certificate" "cert" {
  count = local.use_mtls ? 1 : 0

  domain_name       = var.domain.domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_dns" {
  count           = local.use_mtls ? 1 : 0
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.cert[0].domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.cert[0].domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.cert[0].domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.zone.0.id
  ttl             = 60
}

resource "aws_acm_certificate_validation" "cert_validate" {
  count                   = local.use_mtls ? 1 : 0
  certificate_arn         = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [aws_route53_record.cert_dns[0].fqdn]
}
