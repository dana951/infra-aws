module "helm_release" {
  source = "../../../modules/helm-release"

  name_prefix          = var.name_prefix
  cluster_name         = data.terraform_remote_state.eks_cluster.outputs.cluster_name
  oidc_provider_arn    = data.terraform_remote_state.eks_cluster.outputs.oidc_provider_arn
  oidc_issuer_hostpath = data.terraform_remote_state.eks_cluster.outputs.oidc_issuer_hostpath
  common_tags          = var.common_tags

  helm_charts = var.helm_charts
}
