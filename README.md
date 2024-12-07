# roboshop-terraform

## Terraform Documentation:

#### AWS related:

Terraform Documentation to create VPC - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc

Terraform Documentation to create Subnets - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet

Terraform Documentation to create Route tables - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table

Terraform Documentation to create route table association - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association

#### Github Actions:

Using self-hosted runners in a workflow - https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/using-self-hosted-runners-in-a-workflow

Using custom labels to route jobs - https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/using-self-hosted-runners-in-a-workflow#using-custom-labels-to-route-jobs

Using labels and groups to route jobs - https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/using-self-hosted-runners-in-a-workflow#using-labels-and-groups-to-route-jobs

#### Split function

Terraform documentation for split function - https://developer.hashicorp.com/terraform/language/functions/split

In this project, we are using split function to update tags with the corresponding aws az information. 
Format:
````
split(separator, string)
````
split("-", "us-east-1a") - provides "us" "east" "1a"
split("-", "us-east-1a")[2] - provides "1a"
var.availability_zones[count.index] - us-east-1a, us-east-1b
{split("-", var.availability_zones[count.index])[2]} - 1a, 1b



