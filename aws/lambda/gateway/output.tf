output "invoke_url" {
  value = aws_api_gateway_stage.stage.invoke_url
}

output "endpoint_urls" {
  value = [
    for path in aws_api_gateway_resource.resource.*.path_part : (
      local.use_domain
      ? "https://${var.domain.domain}/${path}"
      : "${aws_api_gateway_stage.stage.invoke_url}/${path}"
    )
  ]
}

output "stage_arn" {
  value = aws_api_gateway_stage.stage.arn
}
