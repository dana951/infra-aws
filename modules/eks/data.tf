data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}
