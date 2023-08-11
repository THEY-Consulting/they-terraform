data "aws_region" "current" {}

resource "aws_api_gateway_resource" "resource" {
  count = length(var.endpoints)

  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = var.endpoints[count.index].path
}

/* lambda request */

resource "aws_api_gateway_method" "method" {
  count = length(var.endpoints)

  rest_api_id      = aws_api_gateway_rest_api.api.id
  resource_id      = aws_api_gateway_resource.resource[count.index].id
  http_method      = var.endpoints[count.index].method
  authorization    = "NONE" // TODO var.api_authorization
  api_key_required = var.api_key != null && var.endpoints[count.index].api_key_required != false
}

resource "aws_api_gateway_integration" "integration" {
  count = length(var.endpoints)

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource[count.index].id
  http_method = aws_api_gateway_method.method[count.index].http_method

  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.endpoints[count.index].function_arn}/invocations"
  integration_http_method = "POST"
}

/* options request */

resource "aws_api_gateway_method" "options" {
  count = length(var.endpoints)

  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource[count.index].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options" {
  count = length(var.endpoints)

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource[count.index].id
  http_method = aws_api_gateway_method.options[count.index].http_method

  type                 = "MOCK"
  passthrough_behavior = "NEVER"
  request_templates    = { "application/json" = jsonencode({ statusCode : 200 }) }
}

resource "aws_api_gateway_integration_response" "options" {
  count = length(var.endpoints)

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource[count.index].id
  http_method = aws_api_gateway_method.options[count.index].http_method
  status_code = aws_api_gateway_method_response.options[count.index].status_code

  response_templates = { "application/json" = "" }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_method_response" "options" {
  count = length(var.endpoints)

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource[count.index].id
  http_method = aws_api_gateway_method.options[count.index].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "true"
    "method.response.header.Access-Control-Allow-Methods" = "true"
    "method.response.header.Access-Control-Allow-Origin"  = "true"
  }
}
