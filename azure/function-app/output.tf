output "id" {
  value = local.function_app.id
}

output "name" {
  value = local.name
}

output "build" {
  value = var.build.enabled ? data.external.builder.0.result : null
}

output "archive_file_path" {
  value = data.archive_file.function_zip.output_path
}

output "endpoint_url" {
  value = "https://${local.function_app.default_hostname}"
}

output "identities" {
  value = local.function_app.identity
}

output "ip_address" {
  value = azurerm_public_ip.public_ip.0.ip_address
}
