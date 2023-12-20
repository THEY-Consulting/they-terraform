output "id" {
  value = azurerm_windows_function_app.function_app.id
}

output "build" {
  value = var.build.enabled ? data.external.builder.0.result : null
}

output "archive_file_path" {
  value = data.archive_file.function_zip.output_path
}

output "endpoint_url" {
  value = "https://${azurerm_windows_function_app.function_app.default_hostname}"
}

output "identities" {
  value = azurerm_windows_function_app.function_app.identity
}
