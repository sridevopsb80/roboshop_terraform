#terraform apply -var-file=env-dev/main.tfvars -auto-approve
#github workflow is getting values for the pipeline to run from this file

env           = "dev"
bastion_nodes = ["172.31.44.168/32"] #IP of the terraform Ec2 machine
zone_id       = "Z02073473N3J0S3WVZG5G"

#defining values for the vpc for dev env. Refer terraform documentation in the readme file.

vpc = {
  cidr               = "10.10.0.0/16"
  public_subnets     = ["10.10.0.0/24", "10.10.1.0/24"]
  web_subnets        = ["10.10.2.0/24", "10.10.3.0/24"]
  app_subnets        = ["10.10.4.0/24", "10.10.5.0/24"]
  db_subnets         = ["10.10.6.0/24", "10.10.7.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b"]
  default_vpc_id     = "vpc-0356e1d486e4ae52b" #fill it with vpc id for default. this is the vpc with the cidr 172.31.0.0/16 where the bastion host resides
  default_vpc_rt     = "rtb-0aa4279d10b72fd93" #fill it with default rt that is associated with the default vpc
  default_vpc_cidr   = "172.31.0.0/16" #fill it with IPv4 CIDR value that is associated with the default vpc
}

#defining values for ec2
apps = {
  frontend = {
    subnet_ref       = "web" #frontend servers are being placed in web subnet. refer diagram in readme
    instance_type    = "t3.small"
    allow_port       = 80
    allow_sg_cidr    = ["10.10.0.0/24", "10.10.1.0/24"] #public subnets being allowed
    allow_lb_sg_cidr = ["0.0.0.0/0"] #incoming traffic being allowed to the internet facing lb
    capacity = { #setting desired auto-scaling threshold
      desired = 1
      max     = 1
      min     = 1
    }
    lb_ref           = "public" #external facing load-balancer
    lb_rule_priority = 1 #rule priority for public lb
  }
  catalogue = {
    subnet_ref       = "app" #catalogue servers are being placed in app subnet. refer diagram in readme
    instance_type    = "t3.small"
    allow_port       = 8080
    allow_sg_cidr    = ["10.10.4.0/24", "10.10.5.0/24"] #app subnets being allowed
    allow_lb_sg_cidr = ["10.10.2.0/24", "10.10.3.0/24", "10.10.4.0/24", "10.10.5.0/24"] #incoming traffic from web subnet and app subnet being allowed to the internal lb sitting between frontend and catalogue
    capacity  = {
      desired = 1
      max     = 1
      min     = 1
    }
    lb_ref           = "private" #internal load-balancer
    lb_rule_priority = 1 #rule priority for private lb
  }

  cart = {
    subnet_ref       = "app" #servers are being placed in app subnet. refer diagram in readme
    instance_type    = "t3.small"
    allow_port       = 8080
    allow_sg_cidr    = ["10.10.4.0/24", "10.10.5.0/24"] #app subnets being allowed
    allow_lb_sg_cidr = ["10.10.2.0/24", "10.10.3.0/24", "10.10.4.0/24", "10.10.5.0/24"] #incoming traffic from web subnet and app subnet being allowed to the internal lb sitting between frontend and catalogue
    capacity = {
      desired = 1
      max     = 1
      min     = 1
    }
    lb_ref           = "private" #internal load-balancer
    lb_rule_priority = 2 #rule priority for private lb
  }
  user = {
    subnet_ref       = "app" #servers are being placed in app subnet. refer diagram in readme
    instance_type    = "t3.small"
    allow_port       = 8080
    allow_sg_cidr    = ["10.10.4.0/24", "10.10.5.0/24"] #app subnets being allowed
    allow_lb_sg_cidr = ["10.10.2.0/24", "10.10.3.0/24", "10.10.4.0/24", "10.10.5.0/24"] #incoming traffic from web subnet and app subnet being allowed to the internal lb sitting between frontend and catalogue
    capacity = {
      desired = 1
      max     = 1
      min     = 1
    }
    lb_ref           = "private"
    lb_rule_priority = 3 #rule priority for private lb
  }
  shipping = {
    subnet_ref       = "app" #servers are being placed in app subnet. refer diagram in readme
    instance_type    = "t3.small"
    allow_port       = 8080
    allow_sg_cidr    = ["10.10.4.0/24", "10.10.5.0/24"] #app subnets being allowed
    allow_lb_sg_cidr = ["10.10.2.0/24", "10.10.3.0/24", "10.10.4.0/24", "10.10.5.0/24"] #incoming traffic from web subnet and app subnet being allowed to the internal lb sitting between frontend and catalogue
    capacity = {
      desired = 1
      max     = 1
      min     = 1
    }
    lb_ref           = "private"
    lb_rule_priority = 4 #rule priority for private lb
  }
  payment = {
    subnet_ref       = "app" #servers are being placed in app subnet. refer diagram in readme
    instance_type    = "t3.small"
    allow_port       = 8080
    allow_sg_cidr    = ["10.10.4.0/24", "10.10.5.0/24"] #app subnets being allowed
    allow_lb_sg_cidr = ["10.10.2.0/24", "10.10.3.0/24", "10.10.4.0/24", "10.10.5.0/24"] #incoming traffic from web subnet and app subnet being allowed to the internal lb sitting between frontend and catalogue
    capacity = {
      desired = 1
      max     = 1
      min     = 1
    }
    lb_ref           = "private"
    lb_rule_priority = 5 #rule priority for private lb
  }
}

#defining values for ec2 for all db. db is a map var

db = {
  mongo = {
    subnet_ref    = "db"
    instance_type = "t3.small"
    allow_port    = 27017
    allow_sg_cidr = ["10.10.4.0/24", "10.10.5.0/24"] #app subnets being allowed
  }
  mysql = {
    subnet_ref    = "db"
    instance_type = "t3.small"
    allow_port    = 3306
    allow_sg_cidr = ["10.10.4.0/24", "10.10.5.0/24"] #app subnets being allowed
  }
  rabbitmq = {
    subnet_ref    = "db"
    instance_type = "t3.small"
    allow_port    = 5672
    allow_sg_cidr = ["10.10.4.0/24", "10.10.5.0/24"] #app subnets being allowed
  }
  redis = {
    subnet_ref    = "db"
    instance_type = "t3.small"
    allow_port    = 6379
    allow_sg_cidr = ["10.10.4.0/24", "10.10.5.0/24"] #app subnets being allowed
  }
}

#define value for load balancer module
load_balancers = {
  private = {
    internal           = true
    load_balancer_type = "application"
    allow_lb_sg_cidr   = ["10.10.2.0/24", "10.10.3.0/24", "10.10.4.0/24", "10.10.5.0/24"] #incoming traffic from web subnet and app subnet being allowed
    subnet_ref         = "app"
    acm_https_arn      = null
    listener_port      = "80"
    listener_protocol  = "HTTP"
    ssl_policy         = null
  }

  public = {
     internal           = false
     load_balancer_type = "application"
     allow_lb_sg_cidr   = ["0.0.0.0/0"] #internet traffic being allowed
     subnet_ref         = "public"
     acm_https_arn = "arn:aws:acm:us-east-1:730335603480:certificate/acabf6ec-3c9e-4949-a9ec-73c29792d1b1" # ACM -> Certificate -> ARN value. value is being provided since lb is internet facing and should use https
    listener_port      = "443"
    listener_protocol  = "HTTPS"
    ssl_policy         = "ELBSecurityPolicy-2016-08"
  }
}
