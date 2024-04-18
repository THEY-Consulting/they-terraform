output "alb_dns" {
  description = "DNS of the application load balancer."
  value       = var.loadbalancer_disabled ? null : aws_lb.lb[0].dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the application load balancer."
  value       = var.loadbalancer_disabled ? null : aws_lb.lb[0].zone_id
}
