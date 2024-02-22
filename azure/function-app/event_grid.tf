/*
 * If no trigger storage account is provided, the function app will use the managed storage account of
 * the azure function itself. Therefore we need to depend on the managed storage account before we can
 * query its properties.
 *
 * This has the side effect, that the data can not be queried during the plan step but only during the run.
 * This means that at plan time, the subscription scope can not be determined and therefore terraform assumes it
 * could have been changed if the managed storage account was modified in any way.
 * Changes in the scope of the subscription also cause the subscription to be recreated.
 *
 * All this is acceptable as long as we manage the storage account ourselves. But external storage accounts
 * could have delete locks implemented which would prevent the subscription from being recreated.
 * Changes in the managed storage account (e.g. changing a tag value) would also cause the subscription
 * to be recreated needlessly (and potentially fail if delete locks exist).
 *
 * That is why this is split into two data sources. One for the managed storage account and one for the external account.
 * The external data source is not dependent on any other resources and can be queried during the plan step.
 *
 * For ease of use, we provide a local variable that contains the correct storage account data source.
 */
data "azurerm_storage_account" "trigger_storage_account_managed" {
  count = var.storage_trigger != null && var.storage_trigger.trigger_storage_account_name == null ? 1 : 0

  name                = data.azurerm_storage_account.storage_account.name
  resource_group_name = data.azurerm_storage_account.storage_account.resource_group_name

  depends_on = [
    azurerm_storage_account.managed_storage_account,
  ]
}
data "azurerm_storage_account" "trigger_storage_account_external" {
  count = var.storage_trigger != null && var.storage_trigger.trigger_storage_account_name != null ? 1 : 0

  name                = var.storage_trigger.trigger_storage_account_name
  resource_group_name = var.storage_trigger.trigger_resource_group_name
}
locals {
  trigger_storage_account = var.storage_trigger != null ? (
    var.storage_trigger.trigger_storage_account_name != null ? data.azurerm_storage_account.trigger_storage_account_external[0] : data.azurerm_storage_account.trigger_storage_account_managed[0]
  ) : null
}

resource "azurerm_eventgrid_event_subscription" "eventgrid_subscription" {
  count = var.storage_trigger != null ? 1 : 0

  name                 = "${var.name}-subscription"
  scope                = local.trigger_storage_account.id
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
