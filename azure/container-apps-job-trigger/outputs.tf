output "id" {
  value = module.trigger_function_app.id
}

output "name" {
  value = module.trigger_function_app.name
}

output "build" {
  value = module.trigger_function_app.build
}

output "archive_file_path" {
  value = module.trigger_function_app.archive_file_path
}

output "endpoint_url" {
  value = module.trigger_function_app.endpoint_url
}

output "identities" {
  value = module.trigger_function_app.identities
}

output "function_name" {
  value = "TriggerContainerJob"
}
