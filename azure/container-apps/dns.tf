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
//NOTE2: currently the managed certificate binding is commented out (see above) because we are mainly using BYOC. 
//we still won't make it dynamic since we are not sure that this is the definitive version or whether we will be using azapi instead.
//resource "null_resource" "create_certificate_binding" {
//  for_each = var.dns_zone != null ? var.container_apps : {}
//
//  provisioner "local-exec" {
//    command = "az containerapp hostname bind --hostname ${each.value.subdomain}.${var.dns_zone.existing_dns_zone_name} -g ${local.resource_group_name} -n ${azurerm_container_app.container_app[each.key].name} --environment ${azurerm_container_app_environment.app_environment.name} --thumbprint ${azurerm_container_app_environment_certificate.app_environment_certificate.thumbprint}"
//  }
//
//  depends_on = [azurerm_container_app.container_app, azurerm_container_app_custom_domain.main, azurerm_container_app_environment_certificate.app_environment_certificate]
//}

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
  ttl                 = var.ttl

  record {
    value = azurerm_container_app_environment.app_environment.custom_domain_verification_id
  }
}

resource "azurerm_dns_cname_record" "main" {
  for_each            = var.dns_zone != null ? var.container_apps : {}
  name                = each.value.subdomain
  resource_group_name = data.azurerm_dns_zone.main[0].resource_group_name
  zone_name           = data.azurerm_dns_zone.main[0].name
  ttl                 = var.ttl

  record = azurerm_container_app.container_app[each.key].latest_revision_fqdn
}

resource "azurerm_container_app_custom_domain" "main" {
  //# TODO?: replace with variable for URL or HOSTNAME
  for_each         = var.dns_zone != null ? var.container_apps : {}
  name             = "${each.value.subdomain}.${var.dns_zone.existing_dns_zone_name}"
  container_app_id = azurerm_container_app.container_app[each.key].id
  container_app_environment_certificate_id = var.unique_environment_certificate != null ? azurerm_container_app_environment_certificate.app_environment_certificate[0].id : azurerm_container_app_environment_certificate.app_environment_certificate[
    index(keys(var.container_apps), each.key)
  ].id
  certificate_binding_type = var.certificate_binding_type

  //NOTE: apparently adding this last 2 attributes solved the destroy problem CertificateInUse: Certificate 'app-env-cert' is used by existing custom domains. 
  //TODO: 
  //  ->add var for binding type
  //  ->check if the null_resource is still necessary
  //  ->maybe conditional creation in case one uses managed certificates?...
  //lifecycle {
  //  // When using an Azure created Managed Certificate these values must be added to ignore_changes to prevent resource recreation.
  //  // src: https://registry.terraform.io/providers/hashicorp/azurerm/3.116.0/docs/resources/container_app_custom_domain
  //  ignore_changes = [certificate_binding_type, container_app_environment_certificate_id]
  //}
}
