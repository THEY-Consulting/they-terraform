# use data source to build and zip the function app,
# this way terraform can decide during plan stage
# if publishing is required or not
data "external" "builder" {
  count = var.build.enabled ? 1 : 0

  program = ["${path.module}/build.sh", var.source_dir, var.build.build_dir, var.build.command]
}

data "archive_file" "function_zip" {
  type        = "zip"
  output_path = coalesce(var.archive.output_path, "dist/${var.name}/lambda.zip")
  source_dir  = var.source_dir
  excludes    = var.archive.excludes

  depends_on = [data.external.builder]
}

resource "aws_lambda_function" "lambda_func" {
  function_name    = var.name
  description      = var.description
  filename         = data.archive_file.function_zip.output_path
  source_code_hash = data.archive_file.function_zip.output_base64sha256
  role             = var.role_arn != null ? var.role_arn : aws_iam_role.role.0.arn
  handler          = var.handler == "index.handler" && var.build.enabled ? "${var.build.build_dir}/index.handler" : var.handler
  runtime          = var.runtime
  architectures    = var.architectures
  publish          = var.publish
  memory_size      = var.memory_size
  timeout          = var.timeout
  layers           = var.layers # TODO: can this be done inside this module?

  dynamic "environment" {
    for_each = var.environment != null ? [var.environment] : []
    content {
      variables = environment.value
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      security_group_ids = vpc_config.value.security_group_ids
      subnet_ids         = vpc_config.value.subnet_ids
    }
  }

  tags = var.tags
}
