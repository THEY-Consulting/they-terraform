output "registry_name" {
  description = "The name of the container registry"
  value       = module.container_registry.name
}

output "registry_login_server" {
  description = "The login server URL for the container registry"
  value       = module.container_registry.login_server
}

output "registry_admin_username" {
  description = "The admin username for the container registry"
  value       = module.container_registry.admin_username
}

output "registry_admin_password" {
  description = "The admin password for the container registry"
  value       = module.container_registry.admin_password
  sensitive   = true
}

output "docker_login_command" {
  description = "Command to login to the container registry"
  value       = "az acr login --name ${module.container_registry.name} || docker login ${module.container_registry.login_server} -u ${module.container_registry.admin_username} -p <password>"
}

output "docker_push_example" {
  description = "Example command to push a Docker image"
  value       = "docker tag your-image:latest ${module.container_registry.login_server}/your-image:latest && docker push ${module.container_registry.login_server}/your-image:latest"
}
