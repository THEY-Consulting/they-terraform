resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = var.tags
}

resource "aws_eip" "main" {
  count  = var.eip_allocation_id == null ? 1 : 0
  domain = "vpc"

  tags = var.tags
}

resource "aws_nat_gateway" "main" {
  allocation_id = coalesce(var.eip_allocation_id, aws_eip.main[0].id)
  subnet_id     = aws_subnet.public.id

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]

  tags = var.tags
}

