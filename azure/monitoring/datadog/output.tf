output "diagnostics" {
  value = {
    eventhub                          = azurerm_eventhub.main.name
    namespace                         = azurerm_eventhub_namespace.main.name
    namespace_authorization_rule_name = azurerm_eventhub_namespace_authorization_rule.sender.name
  }
}
