# use data source to build and zip the function app,
# this way terraform can decide during plan stage
# if publishing is required or not
data "external" "builder" {
  count = var.build.enabled ? 1 : 0

  program = ["${path.module}/build.sh", var.source_dir, var.build.build_dir, var.build.command]
}

data "archive_file" "function_zip" {
  type        = "zip"
  output_path = coalesce(var.archive.output_path, "dist/${var.name}/azure-function-app.zip")
  source_dir  = var.source_dir
  excludes    = var.is_bundle ? concat(var.archive.excludes, ["**/node_modules/**", "**/.yarn/**"]) : var.archive.excludes

  depends_on = [data.external.builder]
}

locals {
  publish_code_command = "az webapp deployment source config-zip --resource-group ${var.resource_group_name} --name ${local.function_app.name} --src ${data.archive_file.function_zip.output_path}"
}
resource "null_resource" "function_app_publish" {
  triggers = {
    input_archive        = data.archive_file.function_zip.output_sha256
    publish_code_command = local.publish_code_command
  }

  provisioner "local-exec" {
    command = local.publish_code_command
  }

  depends_on = [local.publish_code_command]
}
