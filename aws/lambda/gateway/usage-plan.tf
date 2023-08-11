resource "aws_api_gateway_api_key" "api_key" {
  count = var.api_key != null ? 1 : 0

  name        = coalesce(var.api_key.name, "${var.name}-api-key")
  value       = var.api_key.value
  description = var.api_key.description
  enabled     = coalesce(var.api_key.enabled, true)
}

resource "aws_api_gateway_usage_plan" "usage_plan" {
  count = var.api_key != null ? 1 : 0

  name        = coalesce(var.api_key.usage_plan_name, "${var.name}-usage-plan")
  description = var.api_key.usage_plan_description

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.stage.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "usage_plan_key" {
  count = var.api_key != null ? 1 : 0

  key_id        = aws_api_gateway_api_key.api_key.0.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan.0.id
}
