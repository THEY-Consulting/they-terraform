# since we don't have a default VPC, we need to make sure our VPC has connection out
# ToDo: evaluate the necessity of this for when we have a non public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "public_to_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.instances_subnets.0.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.instances_subnets.1.id
  route_table_id = aws_route_table.public.id
}
