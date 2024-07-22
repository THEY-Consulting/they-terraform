# --- RESOURCES / MODULES ---

module "container-instances" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/container-apps"
  source = "../../../azure/container-instances"

  name                = "${terraform.workspace}-they-test-container-instances"
  location            = "Germany West Central"
  container_registry_server =  "testbdb.azurecr.io"
  username            = "testbdb"
  password            = "somepassword"
  environment_variables_backend = { 
      SPRING_PROFILES_ACTIVE = "local,no-auth"
      #SPRING_DATASOURCE_URL = "dummy"
      #SPRING_DATASOURCE_PASSWORD = "dummy"
    }
  environment_variables_frontend = {
      REACT_APP_API_BASE_URL = "https://localhost:8181/api"
      REACT_APP_ENV   = "demo"
      REACT_APP_AUTH0_DOMAIN = "domain"
      REACT_APP_AUTH0_CLIENT_ID = "client"
      //REACT_APP_AUTH0_REDIRECT_URI = "https://localhost:3000"
    }
}

# --- OUTPUT ---
output "backend" {
  value = module.container-instances.backend_fqdn
}

#output "frontend" {
#  value = module.container-apps.frontend_fqdn
#}


