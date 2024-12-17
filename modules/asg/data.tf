data "aws_ami" "rhel9" {
  most_recent = true
  name_regex  = "RHEL-9-DevOps-Practice" #name of the ami
  owners      = ["973714476881"] #amazon owner account number
}