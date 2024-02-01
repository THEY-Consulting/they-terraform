variable "db_name" {
  description = "The name of the database."
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

variable "instance_class" {
    description = "The instance class of database."
    type        = string
    default     = "db.t2.micro"
}

variable "user_name" {
  description = "The master username for the database."
  type        = string
}

variable "password" {
  description = "The master password for the database."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags for the resources."
  type        = map(string)
  default     = {}
}
