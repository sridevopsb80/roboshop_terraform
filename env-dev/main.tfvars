
env           = "dev"
bastion_nodes = ["172.31.91.201/32"]

#defining the vpc for dev env. Refer terraform documentation in the readme file.

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

#defining frontend ec2 for testing
ec2 = {
  frontend = {
    subnet_ref    = "web" #frontend servers are being placed in web subnet. refer diagram in readme
    instance_type = "t3.small"
    allow_port      = 80
    allow_sg_cidr   = ["10.10.0.0/24", "10.10.1.0/24"] #traffic from public subnets being allowed
  }
}