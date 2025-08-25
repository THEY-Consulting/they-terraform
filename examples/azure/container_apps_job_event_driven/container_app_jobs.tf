module "container-apps-job" {
  #source = "github.com/THEY-Consulting/they-terraform//azure/container-apps-job"
  source = "../../../azure/container-apps-job"

  name                = "${terraform.workspace}-event-driven-jobs"
  location            = "Germany West Central"
  resource_group_name = "they-dev"
  enable_log_analytics = true
  
  tags = {
    Project = "they-terraform-examples"
  }
  
  container_app_jobs = {
    queue-processor = {
      name = "queue-processor-job"

      event_trigger_config = {
        parallelism              = 1
        replica_completion_count = 1
        
        scale = {
          min_executions   = 0
          max_executions   = 10
          polling_interval = 30
          
          rules = [
            {
              name = "azure-queue"
              type = "azure-queue"
              metadata = {
                accountName  = "mystorageaccount"
                queueName    = "processing-queue"
                queueLength  = "1"
              }
              auth = [
                {
                  secret_ref        = "queue-connection-string"
                  trigger_parameter = "connection"
                }
              ]
            }
          ]
        }
      }
      
      replica_timeout     = 1800  # 30 minutes
      replica_retry_limit = 3
      
      secret = [
        {
          name  = "queue-connection-string"
          value = "DefaultEndpointsProtocol=https;AccountName=mystorageaccount;AccountKey=your-key-here;EndpointSuffix=core.windows.net"
        }
      ]
      
      template = {
        containers = [
          {
            name   = "queue-worker"
            image  = "mcr.microsoft.com/k8se/quickstart-jobs:latest"
            cpu    = "0.5"
            memory = "1Gi"
            command = ["/bin/bash"]
            args    = ["-c", "echo 'Processing queue message...' && sleep 30 && echo 'Message processed'"]
            env = [
              {
                name        = "QUEUE_CONNECTION"
                secret_name = "queue-connection-string"
              },
              {
                name  = "PROCESSOR_TYPE"
                value = "queue-message"
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
