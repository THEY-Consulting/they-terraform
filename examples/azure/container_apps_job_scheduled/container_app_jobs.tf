module "container-apps-job" {
  #source = "github.com/THEY-Consulting/they-terraform//azure/container-apps-job"
  source = "../../../azure/container-apps-job"

  name                = "${terraform.workspace}-scheduled-jobs"
  location            = "Germany West Central"
  resource_group_name = "they-dev"
  enable_log_analytics = true
  
  tags = {
    Project = "they-terraform-examples"
  }
  
  container_app_jobs = {
    nightly-backup = {
      name         = "nightly-backup-job"
      trigger_type = "Schedule"
      
      schedule_trigger_config = {
        cron_expression          = "0 2 * * *"  # Every day at 2 AM UTC
        parallelism              = 1
        replica_completion_count = 1
      }
      
      replica_timeout     = 7200  # 2 hours
      replica_retry_limit = 3
      
      template = {
        containers = [
          {
            name   = "backup-worker"
            image  = "mcr.microsoft.com/k8se/quickstart-jobs:latest"
            cpu    = "1"
            memory = "2Gi"
            command = ["/bin/bash"]
            args    = ["-c", "echo 'Starting nightly backup...' && sleep 60 && echo 'Backup completed successfully'"]
            env = [
              {
                name  = "BACKUP_TYPE"
                value = "nightly"
              },
              {
                name  = "RETENTION_DAYS"
                value = "30"
              }
            ]
          }
        ]
      }
    }
  }
}

# --- OUTPUT ---
output "container_app_jobs" {
  value = module.container-apps-job.container_app_jobs
}

output "environment_id" {
  value = module.container-apps-job.container_app_environment_id
}
