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

variable "user_data_file_name" {
  description = "Name of file in working directory with user data used in instances of ASG."
  type = string
  default = null # Variable is optional.
}

variable "tags" {
  description = "Additional tags for the Auto Scaling Group."
  type        = map(string)
  default     = {}
}

variable "availability_zones" {
  description = "List of availability zones (AZs). A subnet is created for every AZ and the ASG instances are deployed across the different AZs."
  type        = list(string)
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
