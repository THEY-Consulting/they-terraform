output "arn" {
  value = local.lambda_func.arn
}

output "function_name" {
  value = local.lambda_func.function_name
}

output "invoke_arn" {
  value = local.lambda_func.invoke_arn
}

output "build" {
  value = var.build.enabled ? data.external.builder.0.result : null
}

output "archive_file_path" {
  value = data.archive_file.function_zip.output_path
}
