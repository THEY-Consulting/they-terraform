resource "aws_lb" "lb" {
  count              = var.loadbalancer_disabled ? 0 : 1
  name               = var.name
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
  subnets            = aws_subnet.alb_public_subnets[*].id
  internal           = false # False for internet-facing ALBs.

  dynamic "access_logs" {
    for_each = var.access_logs != null ? [var.access_logs] : []
    content {
      bucket  = access_logs.value["bucket"]
      prefix  = "${access_logs.value["prefix"]}/${var.name}-lb-access-logs"
      enabled = true
    }
  }

  tags = merge(var.tags,
  { Name = var.name })
}

resource "aws_lb_listener" "lb_listener_only_http" {
  # Forward HTTP to target group, if a certificate is
  # provided, HTTP traffic will be redirected to HTTPs
  # with another resource.
  count             = var.loadbalancer_disabled || var.certificate_arn != null ? 0 : 1
  load_balancer_arn = aws_lb.lb[0].arn #Because aws_lb.lb has "count" set, its attributes must be accessed on specific instances.
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = var.loadbalancer_disabled ? null : aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_listener" "lb_listener_redirect_http" {
  # Redirect HTTP traffic to HTTPs if a certificate was
  # provided.
  count             = var.certificate_arn != null ? 1 : 0
  load_balancer_arn = var.loadbalancer_disabled ? null : aws_lb.lb[0].arn #see line 18
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
  load_balancer_arn = var.loadbalancer_disabled ? null : aws_lb.lb[0].arn # see line 18/32 
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = var.loadbalancer_disabled ? null : aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_listener_rule" "https_listener_extra_rules" {
  for_each     = { for index, tg in var.target_groups : index => tg if tg.path_patterns_forwarded_to_target_group_on_default_port != null }
  listener_arn = var.certificate_arn != null ? aws_lb_listener.lb_listener_https[0].arn : aws_lb_listener.lb_listener_only_http[0].arn
  priority     = each.value.path_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.extra[each.key].arn
  }

  condition {
    path_pattern {
      values = each.value.path_patterns_forwarded_to_target_group_on_default_port
    }
  }
}

resource "aws_lb_target_group" "tg" {
  name     = var.name
  port     = var.asg_destination_port
  protocol = "HTTP"
  vpc_id   = local.vpc_id

  health_check {
    path                = var.health_check_path
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }
}

resource "aws_autoscaling_attachment" "asg_tg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  lb_target_group_arn    = aws_lb_target_group.tg.arn
}

resource "aws_lb_target_group" "extra" {
  count = var.loadbalancer_disabled ? 0 : length(var.target_groups)

  name     = "${var.name}-${var.target_groups[count.index].name}"
  port     = var.target_groups[count.index].port
  protocol = "HTTP"
  vpc_id   = local.vpc_id

  health_check {
    path                = var.target_groups[count.index].health_check_path
    timeout             = var.target_groups[count.index].health_check_timeout
    interval            = var.target_groups[count.index].health_check_interval
    unhealthy_threshold = var.target_groups[count.index].health_check_unhealthy_threshold
  }
}

resource "aws_autoscaling_attachment" "asg_tg_extra_attachment" {
  count = length(aws_lb_target_group.extra)

  autoscaling_group_name = aws_autoscaling_group.asg.id
  lb_target_group_arn    = aws_lb_target_group.extra[count.index].arn
}

resource "aws_lb_listener" "lb_extra_listener" {
  count = length(aws_lb_target_group.extra)

  load_balancer_arn = aws_lb.lb[0].arn
  port              = var.target_groups[count.index].port
  protocol          = var.certificate_arn != null ? "HTTPS" : "HTTP"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.extra[count.index].arn
  }
}
