# --- RESOURCES / MODULES ---

module "rds_postgres_database" {
  # source = "github.com/THEY-Consulting/they-terraform//azure/database/rds"
  source = "../../../aws/database/rds"

  db_name        = "app" #DBName must begin with a letter and contain only alphanumeric characters
  engine         = "postgres"
  engine_version = "15.5"
  user_name      = "psql"
  password       = sensitive("Passw0rd123!")

  allocated_storage = 5
  instance_class    = "db.t3.micro"

  publicly_accessible = true


  tags = {
    Project   = "they-terraform-examples"
    CreatedBy = "terraform"
  }
}

# --- OUTPUT ---

output "db_connection_string" {
  value = module.rds_postgres_database.db_connection_string
}

output "hostname" {
  value = module.rds_postgres_database.hostname
}

output "port" {
  value = module.rds_postgres_database.port
}

output "engine" {
  value = module.rds_postgres_database.engine
}

output "db_username" {
  description = "The username for the database"
  value       = module.rds_postgres_database.db_username
}
