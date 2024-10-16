# locals {
#   associate_command = "aws cloudfront associate-alias --alias ${local.domain_without_protocol} --target-distribution-id ${aws_cloudfront_distribution.s3_distribution.id} --region ${data.aws_region.current.name}"
# }

data "aws_region" "current" {}

data "aws_route53_zone" "main" {
  name = local.root_domain
}
#
# data "aws_route53_zone" "ownership" {
#   name = "_${local.domain_without_protocol}"
# }
#
# resource "aws_route53_record" "domain_ownership" {
#   count = var.attach_domain ? 1 : 0
#
#   zone_id = data.aws_route53_zone.ownership.zone_id
#   name    = "_${local.domain_without_protocol}"
#   type    = "TXT"
#   ttl     = "60"
#   records = [aws_cloudfront_distribution.s3_distribution.domain_name]
# }
#
# resource "null_resource" "associate_alias" {
#   count = var.attach_domain ? 1 : 0
#
#   triggers = {
#     domain            = local.domain_without_protocol
#     cloudfront_id     = aws_cloudfront_distribution.s3_distribution.id
#     associate_command = local.associate_command
#   }
#
#   provisioner "local-exec" {
#     command = local.associate_command
#   }
#
#   depends_on = [aws_route53_record.domain_ownership]
# }

resource "aws_route53_record" "frontend" {
  count = var.attach_domain ? 1 : 0

  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.domain_without_protocol
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = true
  }

  #   depends_on = [null_resource.associate_alias]
}
