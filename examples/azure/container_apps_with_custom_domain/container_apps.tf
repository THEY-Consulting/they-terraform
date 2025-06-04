locals {
  resource_group_name = "they-dev"
  key_vault_name      = "they-dev-secrets"
  dns_zone_name       = "they-azure.de"
  subdomain           = "nginx-test"
}

resource "tls_private_key" "demo" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "demo" {
  private_key_pem = tls_private_key.demo.private_key_pem

  subject {
    common_name = "${local.subdomain}.${local.dns_zone_name}"
  }

  validity_period_hours = 24 * 30

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Create PKCS12 bundle with cert + private key
resource "pkcs12_from_pem" "demo" {
  cert_pem        = tls_self_signed_cert.demo.cert_pem
  private_key_pem = tls_private_key.demo.private_key_pem
  password        = "" # No password for simplicity
}

data "azurerm_key_vault" "example" {
  name                = local.key_vault_name
  resource_group_name = local.resource_group_name
}

resource "azurerm_key_vault_secret" "demo_cert" {
  name         = "demo-cert-pkcs12"
  value        = pkcs12_from_pem.demo.result
  key_vault_id = data.azurerm_key_vault.example.id
  content_type = "application/x-pkcs12"
}

module "container-apps" {
  #source = "github.com/THEY-Consulting/they-terraform//azure/container-apps"
  source = "../../../azure/container-apps"

  name                          = "${terraform.workspace}-nginx-test-container-apps"
  location                      = "Germany West Central"
  key_vault_name                = local.key_vault_name
  key_vault_resource_group_name = data.azurerm_key_vault.example.resource_group_name
  use_a_record                  = true # commment out to use CNAME instead of A record

  unique_environment_certificate = {
    name                  = azurerm_key_vault_secret.demo_cert.name
    key_vault_secret_name = azurerm_key_vault_secret.demo_cert.name
  }

  dns_zone = {
    existing_dns_zone_name                = "they-azure.de"
    existing_dns_zone_resource_group_name = local.resource_group_name
  }

  tags = {
    Project    = "they-terraform-examples"
    created_by = "terraform"
  }
  container_apps = {
    nginx-app = {
      name          = "nginx-app"
      revision_mode = "Single"
      subdomain     = local.subdomain
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
  depends_on = [azurerm_key_vault_secret.demo_cert]
}

# --- OUTPUT ---
output "container_apps_urls" {
  value = module.container-apps.container_apps_urls
}
