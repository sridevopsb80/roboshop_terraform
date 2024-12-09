#refer readme file for reference documentation


#Defining private VPC for env
resource "aws_vpc" "main" {
  cidr_block = var.cidr #obtaining cidr info from corresponding env
  tags = {
    Name = "${var.env}-vpc"
  }
}

## Establishing Peering between private VPC and default VPC
resource "aws_vpc_peering_connection" "main" {
  peer_vpc_id = aws_vpc.main.id #private vpc id
  vpc_id      = var.default_vpc_id #default vpc id
  auto_accept = true #to skip manual approval in gui. both VPCs need to be in the same AWS account and region
}

# Since RT for default is already created by aws, adding a route in the default VPC route table to connect to private vpc CIDR
resource "aws_route" "default-vpc-peer-route" {
  route_table_id            = var.default_vpc_rt #route table where entry is being added
  destination_cidr_block    = var.cidr #subnet info for the private vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id #vpc peering connection id
}

#Defining Subnets
resource "aws_subnet" "public" {
  count             = length(var.public_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "public-subnet-${split("-", var.availability_zones[count.index])[2]}"
  }
}

resource "aws_subnet" "web" {
  count             = length(var.web_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.web_subnets[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "web-subnet-${split("-", var.availability_zones[count.index])[2]}"
  }
}
resource "aws_subnet" "app" {
  count             = length(var.app_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnets[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "app-subnet-${split("-", var.availability_zones[count.index])[2]}"
  }
}
resource "aws_subnet" "db" {
  count = length(var.db_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnets[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "db-subnet-${split("-", var.availability_zones[count.index])[2]}"
  }
}

#Defining Route tables

resource "aws_route_table" "public" {
  count  = length(var.public_subnets)
  vpc_id = aws_vpc.main.id

  #routing internet traffic via internet gateway. re: public subnets are being assigned to load balancers and will be receiving incoming traffic from internet
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  # adding a route to default vpc
  route {
    cidr_block                = var.default_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.main.id
  }

  tags = {
    Name = "public-rt-${split("-", var.availability_zones[count.index])[2]}"
  }
}

resource "aws_route_table" "web" {
  count  = length(var.web_subnets)
  vpc_id = aws_vpc.main.id

  #defining routing for nat gateway
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.*.id[count.index] #using splat expression
  }

  # adding a route to default vpc
  route {
    cidr_block                = var.default_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.main.id
  }

  tags = {
    Name = "web-rt-${split("-", var.availability_zones[count.index])[2]}"
  }
}
resource "aws_route_table" "app" {
  count  = length(var.app_subnets)
  vpc_id = aws_vpc.main.id

  #defining routing for nat gateway
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.*.id[count.index] #using splat expression
  }

  # adding a route to default vpc
  route {
    cidr_block                = var.default_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.main.id
  }

  tags = {
    Name = "app-rt-${split("-", var.availability_zones[count.index])[2]}"
  }
}
resource "aws_route_table" "db" {
  count  = length(var.db_subnets)
  vpc_id = aws_vpc.main.id

  #defining routing for nat gateway
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.*.id[count.index] #using splat expression
  }

  # adding a route to default vpc
  route {
    cidr_block                = var.default_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.main.id
  }
  tags = {
    Name = "db-rt-${split("-", var.availability_zones[count.index])[2]}"
  }
}

## Route table association
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public.*.id[count.index] #using splat expression
  route_table_id = aws_route_table.public.*.id[count.index] #using splat expression
}
resource "aws_route_table_association" "web" {
  count          = length(var.web_subnets)
  subnet_id      = aws_subnet.web.*.id[count.index] #using splat expression
  route_table_id = aws_route_table.web.*.id[count.index] #using splat expression
}
resource "aws_route_table_association" "app" {
  count          = length(var.app_subnets)
  subnet_id      = aws_subnet.app.*.id[count.index] #using splat expression
  route_table_id = aws_route_table.app.*.id[count.index] #using splat expression
}
resource "aws_route_table_association" "db" {
  count          = length(var.db_subnets)
  subnet_id      = aws_subnet.db.*.id[count.index] #using splat expression
  route_table_id = aws_route_table.db.*.id[count.index] #using splat expression
}

## Internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.env}-igw"
  }
}

## NAT Gateway
resource "aws_eip" "ngw-ip" {
  count  = length(var.availability_zones)
  domain = "vpc"
}
resource "aws_nat_gateway" "main" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.ngw-ip.*.id[count.index] #using splat expression
  subnet_id     = aws_subnet.public.*.id[count.index] #using splat expression
  tags = {
    Name = "nat-gw-${split("-", var.availability_zones[count.index])[2]}"
  }
}