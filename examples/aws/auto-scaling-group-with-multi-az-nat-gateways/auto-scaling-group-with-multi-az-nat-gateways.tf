# --- DATA ---

data "aws_availability_zones" "azs" {
  state = "available"
}

# --- RESOURCES / MODULES ---

module "auto-scaling-group" {
  # source = "github.com/THEY-Consulting/they-terraform//aws/auto-scaling-group"
  source = "../../../aws/auto-scaling-group"

  name                = "${terraform.workspace}-they-terraform-asg-natgw"
  ami_id              = "ami-0ba27d9989b7d8c5d" # AMI valid for eu-central-1 (Amazon Linux 2023 arm64).
  instance_type       = "t4g.nano"
  desired_capacity    = 3
  min_size            = 1
  max_size            = 3
  user_data_file_name = "user_data.sh"
  availability_zones  = data.aws_availability_zones.azs.names[*] # Use AZs of region defined by provider.
  # Allow all outbound traffic to permit pings and all sorts of requests, e.g. package updates, when the 
  # EC2 instances of the ASG are booting-up.
  allow_all_outbound = true
  multi_az_nat       = true
}

# --- OUTPUT ---

output "alb_dns" {
  value = module.auto-scaling-group.alb_dns
}
