module "container-apps-job" {
  #source = "github.com/THEY-Consulting/they-terraform//azure/container-apps-job"
  source = "../../../azure/container-apps-job"

  name                 = "${terraform.workspace}-scheduled-jobs"
  location             = "Germany West Central"
  resource_group_name  = "they-dev"
  enable_log_analytics = true

  tags = {
    Project = "they-terraform-examples"
  }

  job_secrets = [
    {
      name  = "api-key"
      value = "secret-api-key-value"
    }
  ]

  jobs = {
    hello-world = {
      name = "hello-world-job"

      schedule_trigger_config = {
        cron_expression          = "*/5 * * * *" # Every 5 minutes
        parallelism              = 1
        replica_completion_count = 1
      }

      replica_timeout     = 180 # 3 minutes
      replica_retry_limit = 3

      template = {
        containers = [
          {
            name    = "backup-worker"
            image   = "mcr.microsoft.com/k8se/quickstart-jobs:latest"
            cpu     = "1"
            memory  = "2Gi"
            command = ["/bin/bash"]
            args    = ["-c", "echo 'Hello...' && sleep 15 && echo 'world from $ENVIRONMENT!'"]
            env = [
              {
                name  = "ENVIRONMENT"
                value = "dev" # Non-sensitive value
              },
              {
                name        = "API_KEY"
                secret_name = "api-key" # Sensitive value from secrets
              }
            ]
          }
        ]
      }
    }
  }
}

# --- OUTPUT ---
output "jobs" {
  value = module.container-apps-job.jobs
}

output "environment_id" {
  value = module.container-apps-job.container_app_environment_id
}
