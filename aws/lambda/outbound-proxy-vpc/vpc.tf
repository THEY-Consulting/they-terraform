resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/25" # 128 IPs

  tags = var.tags
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/26" # 64 IPs

  tags = merge(var.tags, { Name = "${var.name}-public" })
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.64/26" # 64 IPs

  tags = merge(var.tags, { Name = "${var.name}-private" })
}

data "aws_security_group" "default" {
  vpc_id = aws_vpc.main.id
  name   = "default"

  tags = var.tags
}

