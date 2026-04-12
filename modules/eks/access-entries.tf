resource "aws_eks_access_entry" "devops_admin_role" {
  cluster_name      = aws_eks_cluster.eks_cluster.name
  principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/DevopsAdminRole"
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "devops_admin_cluster_admin" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = aws_eks_access_entry.devops_admin_role.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
