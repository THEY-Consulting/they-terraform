# --- Endpoint Lambdas ---

resource "aws_lambda_permission" "apigw_lambda_permission" {
  count = length(var.endpoints)

  statement_id  = "allow-lambda-execution-${var.name}-${aws_api_gateway_method.method[count.index].http_method}-${replace(var.endpoints[count.index].path, "/", "-")}"
  action        = "lambda:InvokeFunction"
  function_name = var.endpoints[count.index].function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/${aws_api_gateway_method.method[count.index].http_method}${aws_api_gateway_resource.resource[count.index].path}"
}
# --- Authorizer Lambda ---

resource "aws_lambda_permission" "apigw_authorizer_permission" {
  count = var.authorizer != null ? 1 : 0

  statement_id  = "allow-authorizer-execution-${var.name}"
  action        = "lambda:InvokeFunction"
  function_name = var.authorizer.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}

#resource "aws_iam_role" "invocation_role" {
#  name = "api_gateway_auth_invocation"
#  path = "/"
#
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        "Effect" : "Allow",
#        "Action" : "sts:AssumeRole",
#        "Principal" : {
#          "Service" : "apigateway.amazonaws.com"
#        }
#      },
#    ]
#  })
#
#  inline_policy {
#    name = "invoke_lambda"
#    policy = jsonencode({
#      Version = "2012-10-17"
#      Statement = [{
#        Effect   = "Allow"
#        Action   = ["lambda:InvokeFunction"]
#        Resource = aws_lambda_function.authorizer.arn
#      }]
#    })
#  }
#}
