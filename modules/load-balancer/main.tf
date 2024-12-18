
#security group to allow app related ports
resource "aws_security_group" "load-balancer" {
  name        = "${var.name}-${var.env}-alb-sg"
  description = "${var.name}-${var.env}-alb-sg"
  vpc_id      = var.vpc_id
  #allowing all outbound traffic
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  #allow TCP traffic on 80 port
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = var.allow_lb_sg_cidr
  }
  #allow TCP traffic on 443 port
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = var.allow_lb_sg_cidr
  }
  tags = {
    Name = "${var.name}-${var.env}-alb-sg"
  }
}

#define lb
resource "aws_lb" "main" {
  name               = "${var.name}-${var.env}"
  internal           = var.internal #public or internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load-balancer.id]
  subnets            = var.subnet_ids #subnet value is obtained from main.tfvars in env-dev or prod
  tags = {
    Environment = "${var.name}-${var.env}"
  }
}

#creating aws lb listener to redirect http traffic to https
resource "aws_lb_listener" "public-http" {
  count             = var.internal ? 0 : 1 #if var.internal is false, run this
  load_balancer_arn = aws_lb.main.arn
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

#creating aws lb listener for https to attach target group to the internet facing LB before frontend
#traffic is being forwarded to a target group by default.
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener#forward-action
resource "aws_lb_listener" "public-https" {
  count             = var.internal ? 0 : 1 #if var.internal is false, run this
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_https_arn
  #https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener#fixed-response-action
  #unless we receive a host header, traffic to be sent to appropriate target group. if not, fixed response is 500
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Configuration Error/ Input is not as expected"
      status_code  = "500"
    }
  }
}

#creating aws lb listener for http to attach target group to the internal LB between frontend and catalogue
#traffic is being forwarded to a target group by default.
resource "aws_lb_listener" "internal-http" {
  count = var.internal ? 1 : 0 #if var.internal is true, run this
  load_balancer_arn = aws_lb.main.arn
  port = "80" #apps allow 80 port
  protocol          = "HTTP"
  #https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener#fixed-response-action
  #unless we receive a host header, traffic to be sent to appropriate target group. if not, fixed response is 500
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Configuration Error/ Input is not as expected"
      status_code  = "500"
    }
  }
}

