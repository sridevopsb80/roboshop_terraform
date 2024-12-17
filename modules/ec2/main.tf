#module used to provision ec2

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

#user data is used to run a script while launching an instance. input is base64 encoded
#user data input is being obtained from userdata.sh
resource "aws_instance" "main" {
  ami                    = data.aws_ami.rhel9.image_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.main.id]
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

resource "aws_route53_record" "instance" {
  zone_id = var.zone_id #route53 hosted zone id
  name    = "${var.name}-${var.env}"
  type    = "A"
  ttl     = 10
  records = [aws_instance.main.private_ip]
}







