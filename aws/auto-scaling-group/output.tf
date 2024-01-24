output "alb_dns" {
  description = "DNS of the application load balancer."
  value       = aws_lb.lb.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the application load balancer."
  value       = aws_lb.lb.zone_id
}
