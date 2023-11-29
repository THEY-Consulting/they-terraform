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

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = var.tags
}

resource "aws_nat_gateway" "main" {
  allocation_id = var.eip_allocation_id
  subnet_id     = aws_subnet.public.id

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]

  tags = var.tags
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # public subnet routes to igw
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  # default local route created by aws
  route {
    cidr_block = aws_vpc.main.cidr_block
    gateway_id = "local"
  }

  tags = merge(var.tags, { Name = "${var.name}-public" })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  # private subnet routes to nat gateway
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  # default local route created by aws
  route {
    cidr_block = aws_vpc.main.cidr_block
    gateway_id = "local"
  }

  tags = merge(var.tags, { Name = "${var.name}-private" })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

data "aws_security_group" "default" {
  vpc_id = aws_vpc.main.id
  name   = "default"

  tags = var.tags
}
