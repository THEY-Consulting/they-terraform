# --- DATA ---

data "aws_availability_zones" "azs" {
  state = "available"
}

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

locals {
  bucket_name = "they-test-s3-bucket-${random_string.suffix.id}"
}

# --- RESOURCES / MODULES ---

module "s3_log_bucket_policy" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/s3-bucket/log-bucket-policy"
  source = "../../../aws/s3-bucket/log-bucket-policy"

  bucket_name = local.bucket_name
}

module "s3_bucket" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/s3-bucket"
  source = "../../../aws/s3-bucket"

  # bucket names are blocked for some time (approx. 1hr) after destroy, therefore use a random suffix to create unique names
  name       = local.bucket_name
  versioning = false

  prevent_destroy = false # disable protection for testing purposes, don't do this in production

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = module.s3_log_bucket_policy.policies
  })
}


module "auto-scaling-group" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/auto-scaling-group"
  source = "../../../aws/auto-scaling-group"

  name                = "${substr(terraform.workspace, 0, 5)}-they-terraform-asg-lb-logs"
  ami_id              = "ami-0ba27d9989b7d8c5d" # AMI valid for eu-central-1 (Amazon Linux 2023 arm64).
  instance_type       = "t4g.nano"
  desired_capacity    = 1
  min_size            = 1
  max_size            = 1
  user_data_file_name = "user_data.sh"
  availability_zones  = data.aws_availability_zones.azs.names[*] # Use AZs of region defined by provider.

  access_logs = {
    bucket = module.s3_bucket.id
    prefix = "asg-lb-logs-example"
  }
}

# --- OUTPUT ---

output "alb_dns" {
  value = module.auto-scaling-group.alb_dns
}

output "s3_bucket" {
  value = module.s3_bucket.id
}
