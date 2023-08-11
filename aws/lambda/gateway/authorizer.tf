resource "aws_api_gateway_authorizer" "authorizer" {
  count = var.authorizer != null ? 1 : 0

  name                             = "${var.name}-authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.api.id
  authorizer_uri                   = var.authorizer.invoke_arn
  type                             = var.authorizer.type
  identity_source                  = var.authorizer.identity_source
  authorizer_result_ttl_in_seconds = var.authorizer.result_ttl_in_seconds
  identity_validation_expression   = var.authorizer.identity_validation_expression
}
