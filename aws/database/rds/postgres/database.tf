resource "aws_db_instance" "default" {
  allocated_storage    = 5
  db_name              = var.db_name
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  username             = var.user_name
  password             = var.password
  skip_final_snapshot  = true

  tags = var.tags
}
