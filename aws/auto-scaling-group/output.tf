output "alb_dns" {
  description = "DNS of the application load balancer."
  value       = aws_lb.lb.dns_name
}
