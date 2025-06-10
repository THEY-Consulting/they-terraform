locals {
  name = join("-", compact([
    var.name,
    terraform.workspace,
    contains(["dev", "prod"], terraform.workspace) ? null : "dev",
  ]))
}

resource "azurerm_log_analytics_workspace" "analytics_workspace" {
  name                = "log-${local.name}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = terraform.workspace
    CreatedBy   = "terraform"
  }
}

resource "azurerm_log_analytics_solution" "container_insights" {
  solution_name         = "ContainerInsights"
  location              = data.azurerm_resource_group.main.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.analytics_workspace.id
  workspace_name        = azurerm_log_analytics_workspace.analytics_workspace.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_monitor_diagnostic_setting" "vm_diagnostics" {
  name                       = "diag-${local.name}"
  target_resource_id         = azurerm_linux_virtual_machine.main[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.analytics_workspace.id

  metric {
    category = "AllMetrics"
    enabled  = true
  }

  depends_on = [azurerm_linux_virtual_machine.main]
}
