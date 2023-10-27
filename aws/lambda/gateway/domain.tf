data "aws_route53_zone" "zone" {
  count = local.use_domain ? 1 : 0

  name = var.domain.zone_name
}

resource "aws_api_gateway_domain_name" "api_gateway_domain_name" {
  count = local.use_domain && !local.use_mtls ? 1 : 0

  security_policy = "TLS_1_2"
  certificate_arn = var.domain.certificate_arn
  domain_name     = var.domain.domain
}

resource "aws_api_gateway_domain_name" "api_gateway_domain_name_mtls" {
  count = local.use_domain && local.use_mtls ? 1 : 0

  security_policy          = "TLS_1_2"
  regional_certificate_arn = aws_acm_certificate_validation.cert_validate[0].certificate_arn
  depends_on               = [aws_acm_certificate_validation.cert_validate]

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  mutual_tls_authentication {
    truststore_uri = var.domain.s3_truststore_uri
  }
  domain_name = var.domain.domain
}

resource "aws_api_gateway_base_path_mapping" "base_path_mapping" {
  count = local.use_domain ? 1 : 0

  api_id      = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  domain_name = local.use_mtls ? aws_api_gateway_domain_name.api_gateway_domain_name_mtls[0].domain_name : aws_api_gateway_domain_name.api_gateway_domain_name[0].domain_name
}

resource "aws_route53_record" "api_gateway_domain_name_record" {
  count = local.use_domain ? 1 : 0

  name    = local.use_mtls ? aws_api_gateway_domain_name.api_gateway_domain_name_mtls[0].domain_name : aws_api_gateway_domain_name.api_gateway_domain_name[0].domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.zone[0].id
  alias {
    name    = local.use_mtls ? aws_api_gateway_domain_name.api_gateway_domain_name_mtls[0].regional_domain_name : aws_api_gateway_domain_name.api_gateway_domain_name[0].cloudfront_domain_name
    zone_id = local.use_mtls ? aws_api_gateway_domain_name.api_gateway_domain_name_mtls[0].regional_zone_id : aws_api_gateway_domain_name.api_gateway_domain_name[0].cloudfront_zone_id

    evaluate_target_health = false
  }
}
