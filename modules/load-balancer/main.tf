
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
  subnets            = var.subnet_ids
  tags = {
    Environment = "${var.name}-${var.env}"
  }
}