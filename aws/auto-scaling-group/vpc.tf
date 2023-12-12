resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"
  tags = merge(var.tags, {
    Name = "${terraform.workspace}-${var.name}-vpc"
  })
}

# Allows instances in private IPs to get incoming connections from the internet 
# through an Application Load Balancer. 
# Nonetheless, this resource does not allow an instance in a private subnet to 
# establish internet connections at boot-up (to for example get packages), for that
# refer to AWS NAT.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(var.tags, {
    Name = "${terraform.workspace}-${var.name}-ig"
  })
}

resource "aws_subnet" "subnets" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 4, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = var.public_subnets # Default is false. 
  # Subnets do not have public IPs per default.

  tags = {
    Name = "${terraform.workspace}-${var.name}-subnet-${var.availability_zones[count.index]}"
  }
}

# Security group to allow in/out HTTP traffic.
resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.vpc.id
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
    Name = "${terraform.workspace}-${var.name}-sg"
  }

}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  # Traffic within private subnets.
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
    Name = "${terraform.workspace}-${var.name}-rt"
  })
}

# A route table association should be performed.
# Otherwise, AWS creates another default route table for the VPC,
# and the subnets do not get automatically associated to the correct route table,
# which would mean that internet traffic would not be re-routed to the internet
# gateway.
resource "aws_main_route_table_association" "main_rt" {
  vpc_id         = aws_vpc.vpc.id
  route_table_id = aws_route_table.rt.id
}
