variable "name" {
  description = "Name of ASG."
  type        = string
}

variable "ami_id" {
  description = "ID of AMI used for launch template."
  type        = string
}

variable "instance_type" {
  description = "Instance type used to deploy ASG."
  type        = string
}

variable "desired_capacity" {
  description = "The number of EC2 instances that should be running in the ASG."
  type        = number
  default     = 1
}

variable "min_size" {
  description = "The minimum number of instances in the ASG."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "The maximum number of instances in the ASG."
  type        = number
  default     = 1
}

variable "key_name" {
  description = "Name of key pair used for the instances."
  type        = string
  default     = null
}

variable "user_data_file_name" {
  description = "Name of file in working directory with user data used in instances of ASG."
  type        = string
  default     = null # Variable is optional.
}

variable "user_data" {
  description = "User data to provide when launching instances of ASG. Use this to provide plain text instead of file."
  type        = string
  default     = null # Variable is optional.
}

variable "extra_ebs_volume_size" {
  description = "Size of extra EBS volume to attach to instances."
  type        = number
  default     = null # Variable is optional.
}

variable "min_instance_storage_size_in_gb" {
  description = "Size in GB of the root EBS volume attached to the instances of the ASG."
  type        = number
  default     = null # Variable is optional.
}

variable "tags" {
  description = "Additional tags for the Auto Scaling Group."
  type        = map(string)
  default     = {}
}

variable "loadbalancer_disabled" {
  description = "Indicates whether the load balancer is to be disabled. By default enabled"
  type        = bool
  default     = false
}

variable "availability_zones" {
  description = "List of availability zones (AZs). A subnet is created for every AZ and the ASG instances are deployed across the different AZs."
  type        = list(string)
}

variable "single_availability_zone" {
  description = "Specify true to deploy all ASG instances in the same zone. Otherwise, the ASG will be deployed across multiple availability zones."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "ID of VPC where the ASG will be deployed. If not provided, a new VPC will be created."
  type        = string
  default     = null
}

variable "vpc_cidr_block" {
  description = "The CIDR block of the VPC. The subnets will be located within this CIDR."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Specify true to indicate that instances launched into the subnet should be assigned a public IP address."
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ARN of certificate used to setup HTTPs in ALB"
  type        = string
  default     = null # Variable is optional.
}

variable "health_check_path" {
  description = "Destination for the health check request"
  type        = string
  default     = "/"
}

variable "target_groups" {
  description = "List of additional target groups to attach to the ASG instances and forward traffic to"
  type = list(object({
    name              = string
    port              = number
    health_check_path = optional(string, "/")
    path_patterns     = optional(list(string))
    path_priority     = optional(number)
  }))
  default = []
}

variable "policies" {
  description = "List of policies to attach to the ASG instances via IAM Instance Profile"
  type = list(object({
    name   = string
    policy = string
  }))
  default = []
}

variable "permissions_boundary_arn" {
  description = "ARN of the permissions boundary to attach to the IAM Instance Profile"
  type        = string
  default     = null
}

variable "allow_all_outbound" {
  description = "Allow all outbound traffic from instances"
  type        = bool
  default     = false
}

variable "allow_ssh_inbound" {
  description = "Allow SSH inbound traffic from outside the VPC"
  type        = bool
  default     = false
}

variable "multi_az_nat" {
  description = "Specify true to deploy a NAT Gateway in each availability zone (AZ) of the deployment. Otherwise, only a single NAT Gateway will be deployed."
  type        = bool
  default     = false
}

variable "health_check_type" {
  description = "Controls how the health check for the EC2 instances under the ASG is done"
  type        = string
  default     = "ELB"
}

variable "manual_lifecycle" {
  description = "Specify true to force the ASG to wait until lifecycle actions are completed before adding instances to the load balancer"
  type        = bool
  default     = false
}

variable "manual_lifecycle_timeout" {
  description = "The maximum time, in seconds, that an instance can remain in a Pending:Wait state"
  type        = number
  default     = null
}

variable "access_logs" {
  description = "Enables access logs"
  type = object({
    bucket = string
    prefix = string
  })
  default = null
}
