data "azurerm_storage_account" "trigger_storage_account" {
  count = var.storage_trigger != null ? 1 : 0

  name                = coalesce(var.storage_trigger.trigger_storage_account_name, data.azurerm_storage_account.storage_account.name)
  resource_group_name = coalesce(var.storage_trigger.trigger_resource_group_name, data.azurerm_storage_account.storage_account.resource_group_name)

  depends_on = [
    azurerm_storage_account.managed_storage_account,
  ]
}

resource "azurerm_eventgrid_event_subscription" "eventgrid_subscription" {
  count = var.storage_trigger != null ? 1 : 0

  name                 = "${var.name}-subscription"
  scope                = data.azurerm_storage_account.trigger_storage_account.0.id
  included_event_types = var.storage_trigger.events

  azure_function_endpoint {
    function_id = "${local.function_app.id}/functions/${var.storage_trigger.function_name}"

    # defaults, specified to avoid "no-op" changes when 'apply' is re-ran
    max_events_per_batch              = 1
    preferred_batch_size_in_kilobytes = 64
  }

  dynamic "subject_filter" {
    for_each = var.storage_trigger.subject_filter != null ? [var.storage_trigger.subject_filter] : []

    content {
      subject_begins_with = subject_filter.value.subject_begins_with
      subject_ends_with   = subject_filter.value.subject_ends_with
    }
  }

  retry_policy {
    event_time_to_live    = var.storage_trigger.retry_policy.event_time_to_live
    max_delivery_attempts = var.storage_trigger.retry_policy.max_delivery_attempts
  }

  depends_on = [
    null_resource.function_app_publish
  ]
}
