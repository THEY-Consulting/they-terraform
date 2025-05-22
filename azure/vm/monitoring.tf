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

resource "azurerm_monitor_data_collection_rule" "data_collection_rule" {
  name                = "dcr-${local.name}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = var.resource_group_name

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.analytics_workspace.id
      name                  = "log-analytics-destination"
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["log-analytics-destination"]
  }

  data_flow {
    streams      = ["Microsoft-ContainerLog"]
    destinations = ["log-analytics-destination"]
  }

  data_sources {
    syslog {
      name           = "syslog-datasource"
      streams        = ["Microsoft-Syslog"]
      facility_names = ["*"]
      log_levels     = ["*"]
    }
  }

  tags = {
    Environment = terraform.workspace
    CreatedBy   = "terraform"
  }

  depends_on = [azurerm_virtual_machine_extension.ama]
}

resource "azurerm_virtual_machine_extension" "ama" {
  count                      = var.vm_os == "linux" ? 1 : 0
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.main[0].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.14"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "authentication": {
        "managedIdentity": {
          "identifier-name": "mi_res_id",
          "identifier-value": "${azurerm_linux_virtual_machine.main[0].id}"
        }
      }
    }
  SETTINGS

  depends_on = [azurerm_linux_virtual_machine.main]
}

resource "azurerm_monitor_data_collection_rule_association" "main" {
  count                   = var.vm_os == "linux" ? 1 : 0
  name                    = "dcra-${local.name}"
  target_resource_id      = azurerm_linux_virtual_machine.main[0].id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.data_collection_rule.id

  depends_on = [
    azurerm_monitor_data_collection_rule.data_collection_rule,
    azurerm_virtual_machine_extension.ama
  ]
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
