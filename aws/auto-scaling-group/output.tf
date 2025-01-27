output "alb_dns" {
  description = "DNS of the application load balancer."
  value       = var.loadbalancer_disabled ? null : aws_lb.lb[0].dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the application load balancer."
  value       = var.loadbalancer_disabled ? null : aws_lb.lb[0].zone_id
}

output "nat_gateway_ips" {
  description = "Public IPs of the NAT gateways."
  value       = aws_nat_gateway.natgw.*.public_ip
}

output "security_group_id" {
  description = "ID of the security group."
  value       = aws_security_group.sg.id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = aws_subnet.instances_subnets.*.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.alb_public_subnets.*.id
}

output "private_subnet_route_table_ids" {
  description = "IDs of the route tables for the private subnets."
  value       = aws_route_table.rt_private_subnets.*.id
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = local.vpc_id
}
