resource "aws_security_group" "allow_tls" {
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
#using count to create launch template. if count=0, it will not be created. if count=1, it will be created.
#user data is used to run a script while launching an instance. input is base64 encoded
#user data input is being obtained from userdata.sh
#copying the userdata info from ec2 resource to launch_template. this is to make sure ec2 in auto scaling groups also run similar to ec2 instances spun separately
resource "aws_launch_template" "main" {
  count                  = var.asg ? 1 : 0 #if var.asg is set to true, then assign 1, if not 0
  name                   = "${var.name}-${var.env}-lt"
  image_id               = data.aws_ami.rhel9.image_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
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
##using count to create asg. if count=0, it will not be created. if count=1, it will be created.
resource "aws_autoscaling_group" "main" {
  count               = var.asg ? 1 : 0 #if var.asg is set to true, then assign 1, if not 0
  name                = "${var.name}-${var.env}-asg"
  desired_capacity    = var.capacity["desired"]
  max_size            = var.capacity["max"]
  min_size            = var.capacity["min"]
  vpc_zone_identifier = var.subnet_ids #list of subnets
  target_group_arns   = [aws_lb_target_group.main.*.arn[count.index]] #attaching target group
    launch_template {
    id      = aws_launch_template.main.*.id[0] #since aws_launch_template.main has "count" set, its attributes must be accessed on specific instances
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true #tag is populated when ec2 is launched
    value               = "${var.name}-${var.env}"
  }
}

#using count to create instance. if count=1, it will not be created. if count=0, it will be created.
#user data is used to run a script while launching an instance. input is base64 encoded
#user data input is being obtained from userdata.sh
resource "aws_instance" "main" {
  count                  = var.asg ? 0 : 1 #if var.asg is set to true, then assign value 0, if not 1
  ami                    = data.aws_ami.rhel9.image_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    env         = var.env
    role_name   = var.name
    vault_token = var.vault_token
  }))
  tags = {
    Name = "${var.name}-${var.env}"
  }
}

#creating route53_record for instances
##using count to create r53 record. if count=0, it will not be created. if count=1, it will be created.
resource "aws_route53_record" "instance" {
  count   = var.asg ? 0 : 1 #if var.asg is set to true, then assign value 0, if not 1
  zone_id = var.zone_id #route53 hosted zone id
  name    = "${var.name}-${var.env}"
  type    = "A"
  ttl     = 10
  records = [aws_instance.main.*.private_ip[count.index]]
}

#creating security group for load balancer
#using count to create security group. if count=0, it will not be created. if count=1, it will be created.
resource "aws_security_group" "load-balancer" {
  count       = var.asg ? 1 : 0 #if var.asg is set to true, then assign value 0, if not 1
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
    cidr_blocks = var.name == "frontend" ? ["0.0.0.0/0"] : var.allow_sg_cidr #if var.name = frontend, 0.0.0.0/0, else, use var.allow_sg_cidr
  }
  tags = {
    Name = "${var.name}-${var.env}-alb-sg"
  }
}

#using count to create load balancer. if count=0, it will not be created. if count=1, it will be created.
#creating an internal application load balancer between frontend and catalogue
resource "aws_lb" "main" {
  count              = var.asg ? 1 : 0 #if var.asg is set to true, then assign value 0, if not 1. lb to be created only when asg is being created. using same criteria as we have in asg
  name               = "${var.name}-${var.env}"
  internal           = var.internal #using a variable to create lb. true = internal LB. false =public lb
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load-balancer.*.id[count.index]]
  subnets            = var.lb_subnet_ids #subnet value is obtained from main.tfvars in env-dev or prod
  tags = {
    Environment = "${var.name}-${var.env}"
  }
}

#creating target group
#using count to create target group. if count=0, it will not be created. if count=1, it will be created.
resource "aws_lb_target_group" "main" {
  count    = var.asg ? 1 : 0 #if var.asg is set to true, then assign value 1, if not 0
  name     = "${var.name}-${var.env}"
  port     = var.allow_port #need to open same ports that are to be opened in the ec2 instances
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 5
    path                = "/health"
    timeout             = 3
  }
}

#creating aws lb listener to attach target group to the internal LB between frontend and catalogue
#traffic is being forwarded to a target group by default.
#using count to create listener. if count=0, it will not be created. if count=1, it will be created.
resource "aws_lb_listener" "front_end" {
  count             = var.asg ? 1 : 0 #if var.asg is set to true, then assign value 1, if not 0
  load_balancer_arn = aws_lb.main.*.arn[count.index]
  port              = "80" #apps allow 80 port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.*.arn[count.index]
  }
}