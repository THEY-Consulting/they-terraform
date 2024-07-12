# --- RESOURCES / MODULES ---

module "container-apps" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/container-apps"
  source = "../../../azure/container-apps"

  name                = "${terraform.workspace}-they-test-container-apps"
  location            = "Germany West Central"
}

# --- OUTPUT ---
output "fqdm" {
  value = module.container-apps.fqdm
}


