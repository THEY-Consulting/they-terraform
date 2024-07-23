# --- RESOURCES / MODULES ---

module "container-instances" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/container-apps"
  source = "../../../azure/container-instances"

  name                = "${terraform.workspace}-they-test-container-instances"
  location            = "Germany West Central"
  container_registry_server =  "testbdb.azurecr.io"
  username            = "testbdb"
  password            = "somepass"
  acr_resource_group = "MSO-test"
  exposed_port = 3000
  tags = {
    environment = "testing"
  }
  containers = [
  {
    name   = "frontend-test"
    image  = "frontend-test:latest"
    cpu    = "2"
    memory = "4"
    environment_variables = {
      REACT_APP_API_BASE_URL = "https://localhost:8181/api"
      REACT_APP_ENV   = "demo"
      REACT_APP_AUTH0_DOMAIN = "domain"
      REACT_APP_AUTH0_CLIENT_ID = "someclientid"
    }
    ports  = { // Adjusted to be a single object
      port     = 3000
      protocol = "TCP"
    }
    #liveness_probe = {
    #  path = "<checkPATH>"
    #  port = 3000
    #  initial_delay_seconds = 100
    #  period_seconds      = 5
    #  failure_threshold = 3
    #  success_threshold = 1
    #  #timeout_seconds = 10
    #}
  },
  {
    name   = "backend-test"
    image  = "backend-test:latest"
    cpu    = "1"
    memory = "2"
    environment_variables = {
      SPRING_PROFILES_ACTIVE = "local,no-auth"
      #SPRING_DATASOURCE_URL = "dummy"
      #SPRING_DATASOURCE_PASSWORD = "dummy"
    }
    ports  = { // Adjusted to be a single object
      port     = 8181
      protocol = "TCP"
    }
  }
]
}

# --- OUTPUT ---
#output "frontend" {
#  value = module.container-instances.frontend_fqdn
#}



