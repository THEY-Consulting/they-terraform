# --- RESOURCES / MODULES ---

module "container-instances" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/container-instances"
  source = "../../../azure/container-instances"

  name                 = "${terraform.workspace}-they-test-container-instances"
  resource_group_name  = "${terraform.workspace}-they-test-container-instances"
  location             = "Germany West Central"
  enable_log_analytics = true
  tags = {
    environment = "testing"
  }
  containers = [
    {
      name   = "aci-test"
      image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
      cpu    = "1"
      memory = "2"
      ports = {
        port     = 80
        protocol = "TCP"
      }
    }
  ]
}

# --- OUTPUT ---
output "container-endpoint" {
  value = module.container-instances.container_endpoint
}



