variable "name" {}
variable "instance_type" {}
variable "allow_port" {}
variable "allow_sg_cidr" {}
variable "subnet_ids" {}
variable "vpc_id" {}
variable "env" {}
variable "bastion_nodes" {}
variable "capacity" {
  default = {}
}
variable "asg" {}
variable "vault_token" {}
variable "zone_id" {}
variable "internal" {
  default = null #if there is no value provided, it will be marked as null. defining the default value as null so that db module in main.tf does not expect value for internal.
}
