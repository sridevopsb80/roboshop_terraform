#terraform apply -var-file=env-dev/main.tfvars -auto-approve
#github workflow is getting values for pipeline to run from this file

env           = "dev"
bastion_nodes = ["172.31.91.201/32"]
zone_id       = "Z02073473N3J0S3WVZG5G"

#defining values for the vpc for dev env. Refer terraform documentation in the readme file.

vpc = {
  cidr               = "10.10.0.0/16"
  public_subnets     = ["10.10.0.0/24", "10.10.1.0/24"]
  web_subnets        = ["10.10.2.0/24", "10.10.3.0/24"]
  app_subnets        = ["10.10.4.0/24", "10.10.5.0/24"]
  db_subnets         = ["10.10.6.0/24", "10.10.7.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b"]
  default_vpc_id     = "vpc-0356e1d486e4ae52b" #fill it with vpc id for default
  default_vpc_rt     = "rtb-0aa4279d10b72fd93" #fill it with default rt
  default_vpc_cidr   = "172.31.0.0/16" #fill it with IPv4 CIDR value
}

#defining values for ec2
apps = {
  frontend = {
    subnet_ref    = "web" #frontend servers are being placed in web subnet. refer diagram in readme
    instance_type = "t3.small"
    allow_port      = 80
    allow_sg_cidr   = ["10.10.0.0/24", "10.10.1.0/24"] #traffic from public subnets being allowed
    capacity = { #setting desired auto-scaling threshold
      desired = 1
      max     = 1
      min     = 1
    }
  }
  catalogue = {
    subnet_ref    = "app" #frontend servers are being placed in app subnet. refer diagram in readme
    instance_type = "t3.small"
    allow_port    = 8080
    allow_sg_cidr = ["10.10.2.0/24", "10.10.3.0/24"] #traffic from web subnets being allowed
    capacity = {
      desired = 1
      max     = 1
      min     = 1
    }
  }
}

#defining values for ec2 for all db. db is a map var

db = {
  mongo = {
    subnet_ref    = "db"
    instance_type = "t3.small"
    allow_port    = 27017
    allow_sg_cidr = ["10.10.4.0/24", "10.10.5.0/24"]
  }
  mysql = {
    subnet_ref    = "db"
    instance_type = "t3.small"
    allow_port    = 3306
    allow_sg_cidr = ["10.10.4.0/24", "10.10.5.0/24"]
  }
  rabbitmq = {
    subnet_ref    = "db"
    instance_type = "t3.small"
    allow_port    = 5672
    allow_sg_cidr = ["10.10.4.0/24", "10.10.5.0/24"]
  }
  redis = {
    subnet_ref    = "db"
    instance_type = "t3.small"
    allow_port    = 6379
    allow_sg_cidr = ["10.10.4.0/24", "10.10.5.0/24"]
  }
}

