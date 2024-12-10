output "vpc_config" {
  value = {
    subnet_ids         = [aws_subnet.private.id]
    security_group_ids = [data.aws_security_group.default.id]
  }
  description = "By attaching this config to the vpc_config block of a lambda function it uses the outbound proxy."
}

output "vpc_arn" {
  value       = aws_vpc.main.arn
  description = "Arn of the created vpc."
}

output "public_outbound_ip" {
  value = aws_nat_gateway.main.public_ip
}
