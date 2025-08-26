module "container-apps-job" {
  #source = "github.com/THEY-Consulting/they-terraform//azure/container-apps-job"
  source = "../../../azure/container-apps-job"

  name                 = "${terraform.workspace}-manual-jobs"
  location             = "Germany West Central"
  resource_group_name  = "they-dev" # If nothing is specified, the module will create a new resource group with the name specified in the name variable.
  enable_log_analytics = true

  tags = {
    Project = "they-terraform-examples"
  }

  secrets = {
    batch-processor = [
      {
        name  = "database-password"
        value = "super-secret-password"
      }
    ]
  }

  jobs = {
    batch-processor = {
      name = "batch-processor-job"

      manual_trigger_config = {
        parallelism              = 3 # Run 3 replicas in parallel
        replica_completion_count = 3 # All 3 must complete successfully
      }

      replica_timeout     = 1800 # 30 minutes
      replica_retry_limit = 1

      template = {
        containers = [
          {
            name    = "batch-worker"
            image   = "mcr.microsoft.com/k8se/quickstart-jobs:latest"
            cpu     = "0.25"
            memory  = "0.5Gi"
            command = ["/bin/bash"]
            args    = ["-c", "echo 'Processing batch job...' && sleep 30 && echo 'Batch job completed'"]
            env = [
              {
                name  = "WORKER_ID"
                value = "batch-worker" # Non-sensitive configuration
              },
              {
                name  = "LOG_LEVEL"
                value = "INFO" # Non-sensitive configuration
              },
              {
                name        = "DATABASE_PASSWORD"
                secret_name = "database-password" # Sensitive value from secrets
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
