locals {
  lambda_func = var.dd_api_key == null ? aws_lambda_function.lambda_func[0] : module.lambda-datadog[0]
}

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
  source_dir  = var.is_bundle ? "${var.source_dir}/dist" : var.source_dir
  excludes    = var.is_bundle ? null : var.archive.excludes

  depends_on = [data.external.builder]
}

resource "aws_lambda_function" "lambda_func" {
  count = var.dd_api_key == null ? 1 : 0

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

  dynamic "file_system_config" {
    for_each = var.mount_efs != null ? [var.mount_efs] : []
    content {
      arn              = file_system_config.value
      local_mount_path = "/mnt/efs"
    }
  }

  tags = var.tags
}

module "lambda-datadog" {
  count = var.dd_api_key != null ? 1 : 0

  source  = "DataDog/lambda-datadog/aws"
  version = "2.0.0"

  environment_variables = merge({
    #     "DD_API_KEY_SECRET_ARN" : # TODO
    "DD_API_KEY" : var.dd_api_key
    "DD_ENV" : terraform.workspace
    "DD_SERVICE" : var.dd_service
    "DD_SITE" : var.dd_site
    #     "DD_VERSION" : var.version_tag # TODO?
  }, var.environment)

  # AWS_lambda_function arguments, these get passed to the lambda function.
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

  # Blocks are transformed, for more details see:
  # https://github.com/DataDog/terraform-aws-lambda-datadog?tab=readme-ov-file#inputs
  vpc_config_security_group_ids = var.vpc_config != null ? var.vpc_config.security_group_ids : null
  vpc_config_subnet_ids         = var.vpc_config != null ? var.vpc_config.subnet_ids : null

  file_system_config_arn              = var.mount_efs != null ? var.mount_efs : null
  file_system_config_local_mount_path = "/mnt/efs"

  tags = var.tags
}
