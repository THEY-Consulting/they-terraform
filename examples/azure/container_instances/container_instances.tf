# --- RESOURCES / MODULES ---

module "container-instances" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/container-apps"
  source = "../../../azure/container-instances"

  name                = "${terraform.workspace}-they-test-container-instances"
  location            = "Germany West Central"
  container_registry_server =  "testbdb.azurecr.io"
  username            = "testbdb"
  password            = "password"
}

# --- OUTPUT ---
output "backend" {
  value = module.container-instances.backend_fqdn
}

#output "frontend" {
#  value = module.container-apps.frontend_fqdn
#}


