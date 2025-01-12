#############################

#EKS Cluster definition - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster
#aws_iam_role defined in iam.tf
#EKS node group definition - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group

#############################
#Creating EKS cluster based on env
resource "aws_eks_cluster" "main" {
  name     = "${var.env}-eks"
  role_arn = aws_iam_role.eks-cluster.arn
  vpc_config {
    subnet_ids = var.subnet_ids
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