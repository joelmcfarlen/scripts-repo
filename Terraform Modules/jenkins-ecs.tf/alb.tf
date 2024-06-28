resource "aws_security_group" "jenkins_security_group" {
  name        = "momd-${terraform.workspace}-jenkins-alb-sg"
  description = "Security group for Jenkins instances"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   }
 }

resource "aws_lb" "jenkins_load_balancer" {
  name               = "momd-jenkins-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.jenkins_security_group.id]
  subnets            = var.public_subnet_id
}

resource "aws_lb_target_group" "jenkins_ecs_target_group" {
  name        = "momd-${terraform.workspace}-jenkins-TG"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/login"
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }
 }

resource "aws_lb_listener" "jenkins_listener_http" {
  load_balancer_arn = aws_lb.jenkins_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "OK"
    }
  }
}

resource "aws_lb_listener" "jenkins_listener_https" {
  load_balancer_arn = aws_lb.jenkins_load_balancer.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  certificate_arn   = var.jenkins_alb_cert

  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "OK"
    }
  }
}

resource "aws_lb_listener_rule" "jenkins_listener_rule_http" {
  listener_arn = aws_lb_listener.jenkins_listener_http.arn
  priority     = 10000 

  condition {
    host_header {
     values = ["jenkins.${var.hosted_zone_name}"]
  }
}
  action {
    type          = "redirect"
    
    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener_rule" "jenkins_listener_rule_https" {
  listener_arn = aws_lb_listener.jenkins_listener_https.arn
  priority     = 10001

  dynamic "condition" {
    for_each = [var.hosted_zone_name]

    content {
      host_header {
        values = ["jenkins.${var.hosted_zone_name}"]
      }
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins_ecs_target_group.arn
  }

  tags = {
    Name = "momd-${terraform.workspace}-jenkins-listener-rule"
  }
}
