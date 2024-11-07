resource "aws_api_gateway_rest_api" "api" {
  name                         = var.name
  description                  = var.description
  disable_execute_api_endpoint = anytrue(var.disable_default_endpoint, local.use_mtls)
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = coalesce(var.redeployment_trigger, sha1(jsonencode([
      var.endpoints,
      var.authorizer,
      var.api_key,
    ])))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.integration,
    aws_api_gateway_integration.options,
    aws_api_gateway_integration_response.options,
    aws_api_gateway_method_response.options,
  ]
}

resource "aws_api_gateway_stage" "stage" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  stage_name    = var.stage_name
}
