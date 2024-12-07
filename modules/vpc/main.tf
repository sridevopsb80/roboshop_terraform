#refer readme file for reference documentation

resource "aws_vpc" "main" {
  cidr_block = var.cidr #obtaining cidr info from corresponding env
  tags = {
    Name = "${var.env}-vpc"
  }
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "web" {
  count             = length(var.web_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.web_subnets[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "web-subnet"
  }
}
resource "aws_subnet" "app" {
  count             = length(var.app_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnets[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "app-subnet"
  }
}
resource "aws_subnet" "db" {
  count = length(var.db_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnets[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "db-subnet"
  }
}