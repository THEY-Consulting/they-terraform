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
