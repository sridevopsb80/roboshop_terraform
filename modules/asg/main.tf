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

  #choosing spot instances to reduce cost
  instance_market_options {
    market_type = "spot"
  }

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

#creating dns records for apps instances which will be routed via lb. catalogue.dev.sridevopsb80.site will have a cname pointing to the load balancer public.dev-...
resource "aws_route53_record" "lb" {
  zone_id = var.zone_id
  name    = "${var.name}.${var.env}"
  type    = "CNAME" #maps one domain name to another
  ttl     = 10
  records = [var.dns_name] #aws_lb.main.dns_name value
}

#create a listener rule to forward traffic to target group, provided the host header condition is satisfied
resource "aws_lb_listener_rule" "listener-rule" {
  listener_arn = var.listener_arn
  priority     = var.lb_rule_priority
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
  condition {
    host_header {
      values = [aws_route53_record.lb.fqdn] #ex:frontend.dev.sridevops.site
    }
  }
}