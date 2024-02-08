resource "aws_lb" "lb" {
  name               = "${var.name}"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
  subnets            = aws_subnet.alb_public_subnets[*].id
  internal           = false # False for internet-facing ALBs.

  tags = merge(var.tags,
  { Name = "${var.name}" })
}

resource "aws_lb_listener" "lb_listener_only_http" {
  # Forward HTTP to target group, if a certificate is
  # provided, HTTP traffic will be redirected to HTTPs
  # with another resource.
  count             = var.certificate_arn == null ? 1 : 0
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_listener" "lb_listener_redirect_http" {
  # Redirect HTTP traffic to HTTPs if a certificate was
  # provided.
  count             = var.certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "lb_listener_https" {
  # Do not create an HTTPs listener,
  # if no certificate_arn is provided.
  count             = var.certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.lb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "${var.name}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    path = var.health_check_path
  }
}

resource "aws_autoscaling_attachment" "asg_tg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  lb_target_group_arn    = aws_lb_target_group.tg.arn
}
