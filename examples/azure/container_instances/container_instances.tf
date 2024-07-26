# --- RESOURCES / MODULES ---

module "container-instances" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/container-instances"
  source = "../../../azure/container-instances"

  name                = "${terraform.workspace}-they-test-container-instances"
  resource_group_name = "${terraform.workspace}-they-test-container-instances"
  location            = "Germany West Central"
  registry_credential = {
    server   = "servername"
    username = "testbdb"
    password = "password"
  }
  dns_a_record_name = terraform.workspace
  dns_resource_group = "dns_name"
  dns_record_ttl = 300
  dns_zone_name = "dns.de"
  exposed_port = [{
      port     = 3000 
      protocol = "TCP"
    },{
     port     = 8181 
      protocol = "TCP"
    }
    ]
  tags = {
    environment = "testing"
  }
  containers = [
  {
    name   = "frontend-test"
    image  = "servername/frontend-test:latest"
    cpu    = "2"
    memory = "4"
    environment_variables = {
      REACT_APP_API_BASE_URL = "https://localhost:8181/api"
      REACT_APP_ENV   = "demo"
      REACT_APP_AUTH0_DOMAIN = "domain"
      REACT_APP_AUTH0_CLIENT_ID = "client"
    }
    ports  = {
      port     = 3000
      protocol = "TCP"
    }
    #liveness_probe = {
    #  path = "/"
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
    image  = "servername/backend-test:latest"
    cpu    = "1"
    memory = "2"
    environment_variables = {
      SPRING_PROFILES_ACTIVE = "local,no-auth"
      #SPRING_DATASOURCE_URL = "jdbc:postgresql://localhost:5432/mitglieder-verwaltung"
      #SPRING_DATASOURCE_PASSWORD = "pass"
    }
    ports  = {
      port     = 8181
      protocol = "TCP"
    }
  }
]
}

# --- OUTPUT ---
output "container-fdqn" {
  value = module.container-instances.container_fqdn
}



