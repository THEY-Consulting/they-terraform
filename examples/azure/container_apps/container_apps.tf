# --- RESOURCES / MODULES ---

module "container-apps" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/container-apps"
  source = "../../../azure/container-apps"

  name                = "${terraform.workspace}-they-test-container-apps"
  location            = "Germany West Central"
  container_registry_server =  "testbdb.azurecr.io"
}

# --- OUTPUT ---
output "backend" {
  value = module.container-apps.backend_fqdn
}

output "frontend" {
  value = module.container-apps.frontend_fqdn
}


