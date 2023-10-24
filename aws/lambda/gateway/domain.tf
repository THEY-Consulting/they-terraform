data "aws_route53_zone" "zone" {
  count = var.domain != null ? 1 : 0

  name = var.domain.zone_name
}

resource "aws_api_gateway_domain_name" "api_gateway_domain_name" {
  depends_on = [aws_acm_certificate_validation.cert_validate]
  count = var.domain != null ? 1 : 0

  regional_certificate_arn = aws_acm_certificate_validation.cert_validate.certificate_arn
  domain_name     = var.domain.domain

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  mutual_tls_authentication {
    truststore_uri = var.trustStoreUri
  }
}

resource "aws_api_gateway_base_path_mapping" "base_path_mapping" {
  count = var.domain != null ? 1 : 0

  api_id      = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  domain_name = aws_api_gateway_domain_name.api_gateway_domain_name.0.domain_name
}

resource "aws_route53_record" "api_gateway_domain_name_record" {
  count = var.domain != null ? 1 : 0

  name    = aws_api_gateway_domain_name.api_gateway_domain_name.0.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.zone.0.id
  alias {
    name                   = aws_api_gateway_domain_name.api_gateway_domain_name.0.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.api_gateway_domain_name.0.regional_zone_id
    evaluate_target_health = false
  }
}
