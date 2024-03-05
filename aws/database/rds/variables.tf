variable "db_identifier" {
  description = "Unique name used to identify your database in the aws console"
  type        = string
}

variable "engine" {
  description = "The database engine."
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "The database engine version."
  type        = string
  default     = "15.5"
}

variable "user_name" {
  description = "The main username for the database."
  type        = string
  default     = "psql"
}

variable "password" {
  description = "The main password for the database."
  type        = string
  sensitive   = true
}

variable "allocated_storage" {
  description = "The allocated storage in GBs."
  type        = number
  default     = 5
}

variable "max_allocated_storage" {
  description = "The upper limit to which RDS can automatically scale the storage of the DB instance."
  type        = number
  default     = 30
}

variable "instance_class" {
  description = "The instance class of database."
  type        = string
  default     = "db.t4g.micro"
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted. If true is specified, no DBSnapshot is created."
  type        = bool
  default     = false
}

variable "storage_type" {
  description = "The storage type of the database."
  type        = string
  default     = "gp2"
}

variable "backup_retention_period" {
  description = "The days to retain backups for."
  type        = number
  default     = 14
}

variable "backup_window" {
  description = "The daily time range during which automated backups are created if they are enabled."
  type        = string
  default     = "03:00-04:00"
}

variable "publicly_accessible" {
  description = "Whether the database is publicly accessible."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags for the resources."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/24"
}


