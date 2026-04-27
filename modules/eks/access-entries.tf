locals {
  eks_admin_roles = {
    devops_admin       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/DevopsAdminRole"
    terraform_executor = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TerraformExecutionRole"
  }
}

resource "aws_eks_access_entry" "cluster_admin_roles" {
  for_each = local.eks_admin_roles

  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "cluster_admin_roles" {
  for_each = local.eks_admin_roles

  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = aws_eks_access_entry.cluster_admin_roles[each.key].principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

}
