# creates binding from custom domain to container app, see comment in azurerm_container_app for more info
# NOTE: current bug in terraform provider azure makes it impossible to modify/destroy resources after the binding, so it is
# necessary to delete binding manually in azure portal before destroying the resource
# https://github.com/hashicorp/terraform-provider-azurerm/pull/25972
//resource "null_resource" "create_certificate_binding" {
//  for_each = var.dns_zone != null ? var.container_apps : {}
//
//  provisioner "local-exec" {
//    command = "az containerapp hostname bind --hostname ${each.value.subdomain}.${var.dns_zone.existing_dns_zone_name} -g ${local.resource_group_name} -n ${azurerm_container_app.container_app[each.key].name} --environment ${azurerm_container_app_environment.app_environment.name} --validation-method CNAME"
//  }
//
//  depends_on = [azurerm_container_app.container_app, azurerm_container_app_custom_domain.main]
//}

//also creates binding from custom domain to container app, but for bringing your own certificate
//NOTE: explore if "azapi_resource" helps somehow
resource "null_resource" "create_certificate_binding" {
  for_each = var.dns_zone != null ? var.container_apps : {}

  provisioner "local-exec" {
    command = "az containerapp hostname bind --hostname ${each.value.subdomain}.${var.dns_zone.existing_dns_zone_name} -g ${local.resource_group_name} -n ${azurerm_container_app.container_app[each.key].name} --environment ${azurerm_container_app_environment.app_environment.name} --thumbprint ${azurerm_container_app_environment_certificate.example.thumbprint}"
  }

  depends_on = [azurerm_container_app.container_app, azurerm_container_app_custom_domain.main, azurerm_container_app_environment_certificate.example]
}

//workaround to assigne managed identity to container app environment: as of now, the azurerm_container_app_environment does not support managed identity
resource "null_resource" "assign_managed_identity" {
  provisioner "local-exec" {
    command = "az containerapp env identity assign --name ${azurerm_container_app_environment.app_environment.name} --resource-group ${local.resource_group_name} --system-assigned"
  }
  depends_on = [azurerm_container_app_environment.app_environment]
}

//Enables cors for container apps to specific origins
resource "null_resource" "cors_enabled" {
  for_each = {
    for k, v in var.container_apps : k => v
    if v.cors_enabled == true
  }

  provisioner "local-exec" {
    command = "az containerapp ingress cors enable -n ${azurerm_container_app.container_app[each.key].name} -g ${local.resource_group_name} --allowed-origins ${each.value.cors_allowed_origins}"
  }

  depends_on = [azurerm_container_app.container_app]

}


data "azurerm_dns_zone" "main" {
  count               = var.dns_zone != null ? 1 : 0
  name                = var.dns_zone.existing_dns_zone_name
  resource_group_name = var.dns_zone.existing_dns_zone_resource_group_name
}

# https://learn.microsoft.com/en-us/azure/container-apps/custom-domains-managed-certificates?pivots=azure-portal
resource "azurerm_dns_txt_record" "main" {
  for_each            = var.dns_zone != null ? var.container_apps : {}
  name                = "asuid.${each.value.subdomain}" # asuid. is azure specific and required as prefix
  resource_group_name = data.azurerm_dns_zone.main[0].resource_group_name
  zone_name           = data.azurerm_dns_zone.main[0].name
  ttl                 = 300

  record {
    value = azurerm_container_app_environment.app_environment.custom_domain_verification_id
  }
}

resource "azurerm_dns_cname_record" "main" {
  for_each            = var.dns_zone != null ? var.container_apps : {}
  name                = each.value.subdomain
  resource_group_name = data.azurerm_dns_zone.main[0].resource_group_name
  zone_name           = data.azurerm_dns_zone.main[0].name
  ttl                 = 300

  record = azurerm_container_app.container_app[each.key].latest_revision_fqdn
}

resource "azurerm_container_app_custom_domain" "main" {
  //# TODO?: replace with variable for URL or HOSTNAME
  for_each         = var.dns_zone != null ? var.container_apps : {}
  name             = "${each.value.subdomain}.${var.dns_zone.existing_dns_zone_name}"
  container_app_id = azurerm_container_app.container_app[each.key].id
  lifecycle {
    // When using an Azure created Managed Certificate these values must be added to ignore_changes to prevent resource recreation.
    // src: https://registry.terraform.io/providers/hashicorp/azurerm/3.116.0/docs/resources/container_app_custom_domain
    ignore_changes = [certificate_binding_type, container_app_environment_certificate_id]
  }
}
