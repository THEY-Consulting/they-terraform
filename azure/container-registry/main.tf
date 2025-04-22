resource "azurerm_container_registry" "acr" {
  name                          = var.name
  resource_group_name           = var.resource_group.name
  location                      = var.resource_group.location
  sku                           = var.sku
  admin_enabled                 = var.admin_enabled
  public_network_access_enabled = var.public_network_access_enabled
  zone_redundancy_enabled       = var.zone_redundancy_enabled

  # Premium SKU features
  retention_policy_in_days   = var.sku == "Premium" ? var.retention_policy_days : null
  quarantine_policy_enabled  = var.sku == "Premium" ? var.quarantine_policy_enabled : null
  trust_policy_enabled       = var.sku == "Premium" ? var.trust_policy_enabled : null
  export_policy_enabled      = var.sku == "Premium" ? var.export_policy_enabled : null
  anonymous_pull_enabled     = contains(["Standard", "Premium"], var.sku) ? var.anonymous_pull_enabled : null
  data_endpoint_enabled      = var.sku == "Premium" ? var.data_endpoint_enabled : null
  network_rule_bypass_option = var.sku == "Premium" ? var.network_rule_bypass_option : null

  tags = var.tags

  dynamic "georeplications" {
    for_each = var.sku == "Premium" ? var.geo_replications : []
    content {
      location                  = georeplications.value.location
      zone_redundancy_enabled   = georeplications.value.zone_redundancy_enabled
      regional_endpoint_enabled = georeplications.value.regional_endpoint_enabled
      tags                      = merge(var.tags, georeplications.value.tags)
    }
  }

  dynamic "network_rule_set" {
    for_each = var.sku == "Premium" && var.network_rule_set != null ? [var.network_rule_set] : []
    content {
      default_action = network_rule_set.value.default_action

      dynamic "ip_rule" {
        for_each = toset(network_rule_set.value.ip_rules)
        content {
          action   = "Allow"
          ip_range = ip_rule.value
        }
      }
    }
  }

  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "encryption" {
    for_each = var.encryption != null ? [var.encryption] : []
    content {
      key_vault_key_id   = encryption.value.key_vault_key_id
      identity_client_id = encryption.value.identity_client_id
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}
