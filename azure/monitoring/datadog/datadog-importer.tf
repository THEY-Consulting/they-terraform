module "datadog_importer" {
  source = "../../function-app"

  name                = var.handler_name
  source_dir          = "${path.module}/azure-datadog-importer"
  location            = var.location
  resource_group_name = var.resource_group_name

  runtime = {
    name    = "node"
    version = "~20"
    os      = "windows"
  }

  environment = {
    AzureWebJobsFeatureFlags   = "EnableWorkerIndexing"
    DD_API_KEY                 = var.dd_api_key
    DD_SITE                    = var.dd_site
    EVENTHUB_CONNECTION_STRING = azurerm_eventhub_authorization_rule.reader.primary_connection_string
    DD_TAGS                    = var.dd_tags
    DD_SERVICE                 = var.dd_service
  }

  build = {
    enabled = false
  }

  tags = var.tags
}
