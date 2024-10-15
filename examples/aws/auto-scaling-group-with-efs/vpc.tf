resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${terraform.workspace}-they-terraform-asg-efs"
  }
}

resource "aws_security_group" "efs" {
  name        = "${terraform.workspace}-they-terraform-asg-efs"
  description = "Security group for EFS traffic."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${terraform.workspace}-they-terraform-asg-efs"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_egress" {
  security_group_id = aws_security_group.efs.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # Semantically equivalent to all ports.
}

resource "aws_vpc_security_group_ingress_rule" "allow_nfs_ingress" {
  security_group_id            = aws_security_group.efs.id
  referenced_security_group_id = module.auto-scaling-group.security_group_id
  from_port                    = 2049
  ip_protocol                  = "tcp"
  to_port                      = 2049
}
