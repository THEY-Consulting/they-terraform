module "container-apps" {
  #source = "github.com/THEY-Consulting/they-terraform//azure/container-apps"
  source = "../../../azure/container-apps"

  name                      = "${terraform.workspace}-nginx-test-container-apps"
  location                  = "Germany West Central"
  create_new_resource_group = true
  resource_group_name       = "${terraform.workspace}-nginx-test-container-apps"
  container_apps = {
    nginx-app = {
      name          = "nginx-app"
      revision_mode = "Single"
      subdomain     = "nginx-test"
      ingress = {
        allow_insecure_connections = true
        external_enabled           = true
        target_port                = 80
        traffic_weight = {
          latest_revision = true
          percentage      = 100
        }
      }

      template = {
        max_replicas = 2
        min_replicas = 1
        containers = [
          {
            name   = "nginx"
            image  = "nginx:latest"
            cpu    = "0.25"
            memory = "0.5Gi"
          }
        ]
      }
    }
  }
}

# --- OUTPUT ---
output "container_apps_urls" {
  value = module.container-apps.container_apps_urls
}
