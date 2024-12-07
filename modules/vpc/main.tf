

resource "aws_vpc" "main" {
  cidr_block = var.cidr #obtaining cidr info from corresponding env
  tags = {
    Name = "${var.env}-vpc"
  }
}