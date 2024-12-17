#module used to provision asg with ec2s

#security group to allow app related ports
resource "aws_security_group" "main" {
  name        = "${var.name}-${var.env}-sg"
  description = "${var.name}-${var.env}-sg"
  vpc_id      = var.vpc_id
  #allowing all outbound traffic
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  #allowing inbound TCP traffic from bastion nodes
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = var.bastion_nodes
  }
  #allow inbound TCP traffic on 80 or 8080 port based on ec2 profile - apps or db
  ingress {
    from_port   = var.allow_port
    to_port     = var.allow_port
    protocol    = "TCP"
    cidr_blocks = var.allow_sg_cidr
  }
  #allow inbound TCP traffic on 443 port.
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = var.allow_lb_sg_cidr
  }
  tags = {
    Name = "${var.name}-${var.env}-sg"
  }
}

#creating launch template for ec2 auto-scaling group
#user data is used to run a script while launching an instance. input is base64 encoded
#user data input is being obtained from userdata.sh
#copying the userdata info from ec2 resource to launch_template. this is to make sure ec2 in auto scaling groups also run similar to ec2 instances spun separately
resource "aws_launch_template" "main" {
  name                   = "${var.name}-${var.env}-lt"
  image_id               = data.aws_ami.rhel9.image_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    env         = var.env
    role_name   = var.name
    vault_token = var.vault_token
  }))

  tags = {
    Name = "${var.name}-${var.env}-sg"
  }
}

#creating ec2 auto-scaling group
resource "aws_autoscaling_group" "main" {
  name                = "${var.name}-${var.env}-asg"
  desired_capacity    = var.capacity["desired"]
  max_size            = var.capacity["max"]
  min_size            = var.capacity["min"]
  vpc_zone_identifier = var.subnet_ids #list of subnets
  target_group_arns   = [aws_lb_target_group.main.arn] #attaching target group
  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true #tag is populated when ec2 is launched
    value               = "${var.name}-${var.env}"
  }
}

#creating security group for load balancer
resource "aws_security_group" "load-balancer" {
  name        = "${var.name}-${var.env}-alb-sg"
  description = "${var.name}-${var.env}-alb-sg"
  vpc_id      = var.vpc_id
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = var.allow_lb_sg_cidr
  }
  tags = {
    Name = "${var.name}-${var.env}-alb-sg"
  }
}


#creating an internal application load balancer between frontend and catalogue
resource "aws_lb" "main" {
  name               = "${var.name}-${var.env}"
  internal           = var.internal #using a variable to create lb. true = internal LB. false =public lb
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load-balancer.id]
  subnets            = var.lb_subnet_ids #subnet value is obtained from main.tfvars in env-dev or prod
  tags = {
    Environment = "${var.name}-${var.env}"
  }
}

#creating target group
resource "aws_lb_target_group" "main" {
  name     = "${var.name}-${var.env}"
  port     = var.allow_port #need to open same ports that are to be opened in the ec2 instances
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  #https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group#health_check
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 5
    path                = "/health"
    timeout             = 3
  }
}

#creating aws lb listener for http to attach target group to the internal LB between frontend and catalogue
#traffic is being forwarded to a target group by default.
resource "aws_lb_listener" "internal-http" {
  count             = var.internal ? 1 : 0 #if var.internal is true, run this
  load_balancer_arn = aws_lb.main.arn
  port              = "80" #apps allow 80 port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
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
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
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

#creating dns records for apps instances which will be routed via lb. catalogue.dev.sridevopsb80.site will have a cname pointing to the load balancer internal-catalogue-dev...
resource "aws_route53_record" "lb" {
  zone_id = var.zone_id
  name    = "${var.name}.${var.env}"
  type    = "CNAME" #maps one domain name to another
  ttl     = 10
  records = [aws_lb.main.dns_name]
}