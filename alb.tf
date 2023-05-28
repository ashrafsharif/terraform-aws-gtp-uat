##########################
# Application Load Balancer
###########################

resource "aws_lb" "gtp_uat_app" {
  name               = "gtp-uat-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.gtp_uat_lb.id]
  subnets            = [data.aws_subnets.public.ids[0], data.aws_subnets.public.ids[1]]
}

resource "aws_lb_listener" "gtp_uat_app_https" {
  load_balancer_arn = aws_lb.gtp_uat_app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.gtp_uat_app_cert.arn
  depends_on = [
    aws_lb_target_group.gtp_uat_app_https
  ]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gtp_uat_app_https.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "gtp_uat_app_https" {
  name     = "gtp-uat-app"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.target_vpc.id

  health_check {
    path                = "/index.php"
    port                = 80
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 5
    matcher             = "200"
  }
}

resource "aws_autoscaling_attachment" "gtp_uat_app_https" {
  autoscaling_group_name = aws_autoscaling_group.gtp_uat_app.id
  lb_target_group_arn    = aws_lb_target_group.gtp_uat_app_https.arn
}
