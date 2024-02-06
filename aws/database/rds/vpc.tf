locals {
  vpc_cidr_block = var.vpc_cidr_block
}

resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr_block
  enable_dns_support   = var.publicly_accessible # if DB instance is publicly accessible must be enabled
  enable_dns_hostnames = var.publicly_accessible # if DB instance is publicly accessible must be enabled
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "instances_subnets" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(local.vpc_cidr_block, 4, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.db_name}-subnet-${count.index}"
  }
}

resource "aws_db_subnet_group" "main" {
  subnet_ids = [aws_subnet.instances_subnets.0.id, aws_subnet.instances_subnets.1.id]
}

resource "aws_security_group" "main" {
  name   = "db_traffic"
  vpc_id = aws_vpc.main.id
}

# Only allow incoming traffic from all ipv4 ips on port 5432 if publicly accessible
# if used in production this SHOULD be limited further.
# If this is set to false, the expectation is that accessing party's
# should add a rule to the vpc that they are allowed to access
resource "aws_vpc_security_group_ingress_rule" "main" {
  count             = var.publicly_accessible ? 1 : 0
  security_group_id = aws_security_group.main.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 5432
  ip_protocol = "tcp"
  to_port     = 5432
}
