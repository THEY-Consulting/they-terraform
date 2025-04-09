module "storage_container" {
  source = "../../../azure/storage-container"

  name                = "they-storage-container"
  resource_group_name = "they-dev"
  location            = "Germany West Central"

  container_access_type = "private"
  metadata = {
    environment = "dev"
    department  = "it"
  }

  storage_account = {
    # name = "customstorageaccount" # Optional: Automatically generated from container name if not specified
    preexisting_name = null # If null, a new storage account will be created
    tier             = "Standard"
    replication_type = "LRS"
    kind             = "StorageV2"
    access_tier      = "Hot"
    is_hns_enabled   = false

    # CORS configuration
    cors_rules = [{
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "POST", "PUT"]
      allowed_origins    = ["https://myapp.example.com"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }]
  }

  tags = {
    createdBy   = "Terraform"
    environment = "dev"
  }
}

# Outputs
output "container_id" {
  value = module.storage_container.id
}

output "container_name" {
  value = module.storage_container.name
}

output "storage_account_name" {
  value = module.storage_container.storage_account_name
}

output "storage_account_id" {
  value = module.storage_container.storage_account_id
}

output "container_url" {
  value = module.storage_container.container_url
}

# Sensitive outputs
output "primary_access_key" {
  value     = module.storage_container.primary_access_key
  sensitive = true
}

output "primary_connection_string" {
  value     = module.storage_container.primary_connection_string
  sensitive = true
}
