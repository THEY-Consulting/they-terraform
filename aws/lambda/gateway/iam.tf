# --- Endpoint Lambdas ---

resource "aws_lambda_permission" "apigw_lambda_permission" {
  count = length(var.endpoints)

  statement_id  = "allow-lambda-execution-${var.name}-${aws_api_gateway_method.method[count.index].http_method}-${replace(var.endpoints[count.index].path, "/", "-")}"
  action        = "lambda:InvokeFunction"
  function_name = var.endpoints[count.index].function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/${aws_api_gateway_method.method[count.index].http_method}${aws_api_gateway_resource.resource[count.index].path}"
}
