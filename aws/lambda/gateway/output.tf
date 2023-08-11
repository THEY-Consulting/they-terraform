output "invoke_url" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}

output "endpoint_urls" {
  value = [
    for path in aws_api_gateway_resource.resource.*.path_part : (
      var.domain != null
      ? "https://${var.domain.domain}/${path}"
      : "${aws_api_gateway_deployment.deployment.invoke_url}${aws_api_gateway_stage.stage.stage_name}/${path}"
    )
  ]
}
