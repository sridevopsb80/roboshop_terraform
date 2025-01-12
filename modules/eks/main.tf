#############################

#EKS Cluster documentation - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster
#aws_iam_role defined in iam.tf
#EKS node group documentation - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group
#EKS add-on documentation - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon
#EKS Access policy association documentation - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association
#############################
#Creating EKS cluster based on env
resource "aws_eks_cluster" "main" {
  name     = "${var.env}-eks"
  role_arn = aws_iam_role.eks-cluster.arn
  version  = var.eks_version
  vpc_config {
    subnet_ids = var.subnet_ids
  }
  #Configuration block for the access config associated with your cluster
  #https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }
}

#Creating node group for eks cluster
resource "aws_eks_node_group" "main" {
  for_each        = var.node_groups
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.eks-node.arn
  subnet_ids      = var.subnet_ids
  instance_types  = each.value["instance_types"]
  capacity_type   = each.value["capacity_type"]
  scaling_config {
    desired_size = each.value["min_size"]
    max_size     = each.value["max_size"]
    min_size     = each.value["min_size"]
  }
}

#EKS comes with addons by default. While defining eks via terraform, these addons need to be defined. Refer main.tfvars to check defined addons
resource "aws_eks_addon" "addons" {
  for_each      = var.add_ons
  cluster_name  = aws_eks_cluster.main.name
  addon_name    = each.key
  addon_version = each.value
}

#To provide cluster access to terraform workstation machine
resource "aws_eks_access_policy_association" "workstation-access" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" #replace with correct policy arn
  principal_arn = "arn:aws:iam::730335603480:role/workstation-role" #workstation role info
  access_scope {
    type       = "cluster"
  }
}