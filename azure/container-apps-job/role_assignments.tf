# Role Assignments for Container App Jobs
# This file contains role assignment resources that grant Container App Jobs' managed identities
# access to Azure resources like Storage Accounts, Key Vaults, etc.

# Create role assignments for each job and each role assignment
resource "azurerm_role_assignment" "jobs" {
  for_each = {
    for pair in flatten([
      for assignment_idx, assignment in var.role_assignments : [
        for job_name in keys(var.jobs) : {
          key                  = "${assignment.scope}-${assignment.role_definition_name}-${job_name}"
          scope                = assignment.scope
          role_definition_name = assignment.role_definition_name
          job_name             = job_name
        }
      ]
    ]) : pair.key => pair
  }

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_container_app_job.container_app_job[each.value.job_name].identity[0].principal_id

  depends_on = [azurerm_container_app_job.container_app_job]
}
