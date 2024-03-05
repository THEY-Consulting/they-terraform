resource "aws_db_instance" "main" {
  identifier = var.db_identifier

  engine                     = var.engine
  engine_version             = var.engine_version
  auto_minor_version_upgrade = true

  username = var.user_name
  password = var.password
  port     = 5432

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage

  instance_class = var.instance_class
  multi_az       = var.multi_az
  storage_type   = var.storage_type

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.main.id]

  skip_final_snapshot = var.skip_final_snapshot
  publicly_accessible = var.publicly_accessible
  apply_immediately   = var.apply_immediately
  tags                = var.tags
}
