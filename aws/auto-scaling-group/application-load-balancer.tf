resource "aws_lb" "lb" {
  name               = "${terraform.workspace}-${var.name}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
  subnets            = aws_subnet.subnets[*].id
  internal           = false # False for internet-facing ALBs.

  tags = merge(var.tags,
  { Name = "${terraform.workspace}-${var.name}-alb" })
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "${terraform.workspace}-${var.name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
}
