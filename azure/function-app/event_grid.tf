resource "azurerm_eventgrid_event_subscription" "eventgrid_subscription" {
  count = var.storage_trigger == null ? 0 : 1

  name                 = "${var.name}-subscription"
  scope                = data.azurerm_storage_account.main.id
  included_event_types = var.storage_trigger.events

  azure_function_endpoint {
    function_id = "${azurerm_windows_function_app.function_app.id}/functions/${var.storage_trigger.function_name}"

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
