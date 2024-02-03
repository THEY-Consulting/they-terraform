resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"
  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(var.tags, {
    Name = "${var.name}-ig"
  })
}

# Private subnets in which the instances get private IP addresses.
resource "aws_subnet" "instances_subnets" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 4, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = var.public_subnets # Default is false. 

  tags = {
    Name = "${var.name}-subnet-${var.availability_zones[count.index]}"
  }
}

# TODO: Change inline rules.
# Security group to allow in/out HTTP traffic.
resource "aws_security_group" "sg" {
  name        = "${var.name}-sg"
  description = "Security group for ASG, HTTP and HTTPS traffic."
  vpc_id      = aws_vpc.vpc.id
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-sg"
  }

  # Rule is only deployed if a certificate for HTTPS was provided.  
  dynamic "ingress" {
    for_each = var.certificate_arn != null ? [1] : []
    content {
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Rule is only deployed if a certificate for HTTPS was provided.  
  dynamic "egress" {
    for_each = var.certificate_arn != null ? [1] : []
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Rule is only deployed if variable allow_all_outbound is true.
  dynamic "egress" {
    for_each = var.allow_all_outbound == true ? [1] : []
    content {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

resource "aws_route_table" "rt_private_subnets" {
  count  = var.multi_az_natgw ? length(var.availability_zones) : 1
  vpc_id = aws_vpc.vpc.id

  # Traffic within VPC, e.g. with private subnets.
  route {
    cidr_block = var.vpc_cidr_block
    gateway_id = "local"
  }

  # TODO: the NAT Gateway route depends on the AZ where the private subnet is.

  # Re-route internet traffic to NAT gateway.
  # NAT gateway lies within a public subnet that can 
  # forward internet traffic to the internet gateway.
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw[count.index].id
  }

  tags = merge(var.tags, {
    Name = "${var.name}-rt_private_subnets"
  })
}

resource "aws_route_table" "rt_public_subnets" {
  vpc_id = aws_vpc.vpc.id

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
    Name = "${var.name}-rt_public_subnets"
  })
}

resource "aws_route_table_association" "rta_private" {
  count = length(aws_subnet.instances_subnets)

  route_table_id = aws_route_table.rt_private_subnets[count.index].id
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

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 4, count.index + length(aws_subnet.instances_subnets))
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.name}-alb_subnet-${var.availability_zones[count.index]}"
  }
}

# TODO: Either create 1 or multiple NATGWs.
resource "aws_nat_gateway" "natgw" {
  count = var.multi_az_natgw ? length(var.availability_zones) : 1

  allocation_id = aws_eip.natgw_eip[count.index].id
  subnet_id     = aws_subnet.alb_public_subnets[count.index].id

  tags = merge(var.tags, {
    # TODO: Maybe add AZ to tag.
    Name = "${var.name}-natgw"
  })

  # Terraform docs recommendation:
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_eip" "natgw_eip" {
  # TODO: change for exact number of instances in true case.
  count = var.multi_az_natgw ? length(var.availability_zones) : 1

  domain = "vpc"

  tags = {
    # TODO: maybe change name for only count.index instead of AZ.
    Name = "${var.name}-natgw-eip-${var.availability_zones[count.index]}"
  }
}
