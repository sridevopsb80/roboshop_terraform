resource "aws_security_group" "allow_tls" {
  name        = "${var.name}-${var.env}-sg"
  description = "${var.name}-${var.env}-sg"
  vpc_id      = var.vpc_id
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = var.bastion_nodes
  }
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
