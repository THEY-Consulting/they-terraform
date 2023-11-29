resource "aws_vpc" "main" {
  # TODO: adapt ip range, only need 32IPs..?
  cidr_block = "10.0.0.0/25" # 128 IPs

  tags = var.tags
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  # TODO: adapt to 64 ips
  cidr_block = "10.0.0.0/28" # 16 IPs

  tags = var.tags
}

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id
  # TODO: adapt to 64 ips
  cidr_block = "10.0.0.16/28" # 16 IPs

  tags = var.tags
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

data "aws_security_group" "default" {
  vpc_id = aws_vpc.main.id
  name   = "default"

  tags = var.tags
}
