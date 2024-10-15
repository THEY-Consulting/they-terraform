locals {
  # The total maximum value of NAT Gateways is one NAT Gateway for each 
  # availability zone.
  number_of_nat_gateways = var.multi_az_nat ? length(aws_subnet.instances_subnets) : 1
  vpc_id                 = var.vpc_id == null ? aws_vpc.vpc[0].id : var.vpc_id
}

resource "aws_vpc" "vpc" {
  count = var.vpc_id == null ? 1 : 0

  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"
  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = local.vpc_id

  tags = merge(var.tags, {
    Name = var.name
  })
}

# Private subnets in which the instances get private IP addresses.
resource "aws_subnet" "instances_subnets" {
  count = length(var.availability_zones)

  vpc_id                  = local.vpc_id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 4, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = var.public_subnets # Default is false. 

  tags = {
    Name = "${var.name}-private-${var.availability_zones[count.index]}"
  }
}

resource "aws_security_group" "sg" {
  name        = var.name
  description = "Security group for ASG, HTTP and HTTPS traffic."
  vpc_id      = local.vpc_id

  tags = {
    Name = var.name
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ingress" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_http_egress" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_egress" {
  count = var.allow_all_outbound ? 1 : 0

  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # Semantically equivalent to all ports.
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_ingress" {
  count = var.certificate_arn != null ? 1 : 0

  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_https_egress" {
  count = var.certificate_arn != null ? 1 : 0

  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ingress" {
  count = var.key_name != null && var.allow_ssh_inbound ? 1 : 0

  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_custom_ingress" {
  count = length(var.target_groups)

  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.target_groups[count.index].port
  ip_protocol       = "tcp"
  to_port           = var.target_groups[count.index].port
}

resource "aws_route_table" "rt_private_subnets" {
  # Only create as many route tables as NAT Gateways that were created.
  count = length(aws_nat_gateway.natgw)

  vpc_id = local.vpc_id

  # Traffic within VPC, e.g. with private subnets.
  route {
    cidr_block = var.vpc_cidr_block
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"

    # Re-route internet traffic to NAT gateway in private subnets.
    # NAT gateway lies within a public subnet that can
    # forward internet traffic to the internet gateway.
    nat_gateway_id = var.public_subnets ? null : aws_nat_gateway.natgw[count.index].id

    # Re-route internet traffic to internet gateway in public subnets.
    gateway_id = var.public_subnets ? aws_internet_gateway.igw.id : null
  }

  tags = merge(var.tags, {
    Name = "${var.name}-private"
  })
}

resource "aws_route_table" "rt_public_subnets" {
  vpc_id = local.vpc_id

  # Traffic within VPC, e.g. with private subnets.
  route {
    cidr_block = var.vpc_cidr_block
    gateway_id = "local"
  }

  # Re-route internet traffic to internet gateway.
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.tags, {
    Name = "${var.name}-public"
  })
}

resource "aws_route_table_association" "rta_private" {
  count = length(aws_subnet.instances_subnets)

  # If you do not choose a multi-AZ NAT Gateway deployment, there is only
  # one single NAT Gateway, so there is only one single route table routing
  # traffic to the single NAT Gateway.
  route_table_id = aws_route_table.rt_private_subnets[min(count.index, length(aws_route_table.rt_private_subnets) - 1)].id
  subnet_id      = aws_subnet.instances_subnets[count.index].id
}

resource "aws_route_table_association" "rta_alb_public_subnets" {
  count = length(aws_subnet.alb_public_subnets)

  subnet_id      = aws_subnet.alb_public_subnets[count.index].id
  route_table_id = aws_route_table.rt_public_subnets.id
}

# Public subnets for the ALB nodes in each AZ.
resource "aws_subnet" "alb_public_subnets" {
  count = length(var.availability_zones)

  vpc_id            = local.vpc_id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 4, count.index + length(aws_subnet.instances_subnets))
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.name}-public-${var.availability_zones[count.index]}"
  }
}

resource "aws_nat_gateway" "natgw" {
  count = local.number_of_nat_gateways

  allocation_id = aws_eip.natgw_eip[count.index].id
  subnet_id     = aws_subnet.alb_public_subnets[count.index].id

  tags = merge(var.tags, {
    Name = var.name
  })

  # Terraform docs recommendation:
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_eip" "natgw_eip" {
  count = local.number_of_nat_gateways

  domain = "vpc"

  tags = {
    Name = "${var.name}-${var.availability_zones[count.index]}"
  }
}
