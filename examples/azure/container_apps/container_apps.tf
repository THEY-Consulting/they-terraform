# --- RESOURCES / MODULES ---

module "container-apps" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/container-apps"
  source = "../../../azure/container-apps"

  name                      = "${terraform.workspace}-they-test-container-apps"
  location                  = "Germany West Central"
  create_new_resource_group = true
  resource_group_name       = "${terraform.workspace}-they-test-container-apps"
  container_apps = {
    backend = {
      name          = "backend"
      revision_mode = "Single"
      ingress = {
        allow_insecure_connections = true
        external_enabled           = true
        target_port                = 8181
        traffic_weight = {
          latest_revision = true
          percentage      = 100
        }
      }
      registry = [{
        server               = "yourserver.azurecr.io"
        username             = "username"
        password_secret_name = "registry-secret"
      }]

      secret = {
        name  = "registry-secret"
        value = "your-registry-password"
      }
      template = {
        max_replicas = 3
        min_replicas = 1
        containers = [
          {
            name   = "backend"
            image  = "yourserver.azurecr.io/backend-test:latest"
            cpu    = "0.5"
            memory = "1.0Gi"
          }
        ]
      }
    },
    frontend = {
      name          = "frontend"
      revision_mode = "Single"
      ingress = {
        allow_insecure_connections = true
        external_enabled           = true
        target_port                = 3000
        traffic_weight = {
          latest_revision = true
          percentage      = 100
        }
      }
      registry = [{
        server               = "yourserver.azurecr.io"
        username             = "username"
        password_secret_name = "registry-secret"
      }]

      secret = {
        name  = "registry-secret"
        value = "your-registry-password"
      }
      template = {
        max_replicas = 3
        min_replicas = 1
        containers = [
          {
            name   = "frontend-test"
            image  = "testbdb.azurecr.io/frontend-test:latest"
            cpu    = "2.0"
            memory = "4.0Gi"
          }
        ]
        env = [
          {
            name  = "REACT_APP_API_BASE_URL"
            value = "http://backend:8181"
          },
          {
            name  = "REACT_APP_ENV"
            value = "ANOTHER_ENV_VAR_VALUE"
          }
        ]
      }
    }
  }
}

# --- OUTPUT ---
output "container_app_fqdns" {
  value = module.container-apps.container_app_fqdn
}




