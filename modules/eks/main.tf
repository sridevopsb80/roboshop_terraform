#############################

#EKS Cluster definition - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster
#aws_iam_role defined in iam.tf

#############################
resource "aws_eks_cluster" "main" {
  name     = "${var.env}-eks"
  role_arn = aws_iam_role.eks-cluster.arn
  vpc_config {
    subnet_ids = var.subnet_ids
  }
}