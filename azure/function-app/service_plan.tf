resource "azurerm_service_plan" "managed_service_plan" {
  count = var.service_plan.name == null ? 1 : 0

  name                = "${var.name}-service-plan"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = var.runtime.os == "windows" ? "Windows" : "Linux"
  sku_name            = var.needs_mdm_access ? "P0v3" : var.service_plan.sku_name

  tags = var.tags
}

data "azurerm_service_plan" "service_plan" {
  name                = coalesce(var.service_plan.name, azurerm_service_plan.managed_service_plan.0.name)
  resource_group_name = var.resource_group_name

  depends_on = [
    azurerm_service_plan.managed_service_plan
  ]
}
