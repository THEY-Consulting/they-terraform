module "job_triggers" {
  for_each = {
    for job_key, job in var.jobs : job_key => job
    if job.enable_job_trigger == true
  }

  source = "../container-apps-job-trigger"

  name                = "${each.value.name}-trigger"
  location            = var.location
  resource_group_name = local.resource_group_name

  target_container_app_job_id = azurerm_container_app_job.container_app_job[each.key].id

  tags = merge(var.tags, each.value.tags)
}
