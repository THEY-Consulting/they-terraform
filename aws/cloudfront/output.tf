output "domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "hosted_zone_id" {
  value = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
}

output "arn" {
  value = aws_cloudfront_distribution.s3_distribution.arn
}

output "id" {
  value = aws_cloudfront_distribution.s3_distribution.id
}
