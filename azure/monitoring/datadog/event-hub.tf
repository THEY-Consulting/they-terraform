resource "azurerm_eventhub_namespace" "main" {
  name                = var.eventhub_namespace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  capacity            = var.capacity

  tags = var.tags
}

resource "azurerm_eventhub" "main" {
  name                = "logs"
  resource_group_name = var.resource_group_name

  namespace_name    = azurerm_eventhub_namespace.main.name
  partition_count   = 1
  message_retention = 1
}

resource "azurerm_eventhub_namespace_authorization_rule" "sender" {
  name                = "SendLogs"
  resource_group_name = var.resource_group_name
  namespace_name      = azurerm_eventhub_namespace.main.name

  listen = true
  send   = true
  manage = true
}

resource "azurerm_eventhub_authorization_rule" "reader" {
  name                = "ReadLogs"
  resource_group_name = var.resource_group_name
  namespace_name      = azurerm_eventhub_namespace.main.name
  eventhub_name       = azurerm_eventhub.main.name

  listen = true
  send   = false
  manage = false
}
