locals {
  helm_charts_with_loaded_values = {
    for release_name, chart in var.helm_charts : release_name => merge(
      chart,
      {
        values = [for values_file in lookup(chart, "values", []) : file("${path.module}/${values_file}")]
      },
    )
  }

  argocd_enabled = try(var.helm_charts.argocd.enabled, false)
}

module "helm_release" {
  source = "../../../modules/helm-release"

  name_prefix          = var.name_prefix
  cluster_name         = data.terraform_remote_state.eks_cluster.outputs.cluster_name
  oidc_provider_arn    = data.terraform_remote_state.eks_cluster.outputs.oidc_provider_arn
  oidc_issuer_hostpath = data.terraform_remote_state.eks_cluster.outputs.oidc_issuer_hostpath
  common_tags          = var.common_tags

  helm_charts = local.helm_charts_with_loaded_values
}

resource "kubernetes_manifest" "argocd_main_app" {
  count = local.argocd_enabled ? 1 : 0

  manifest = yamldecode(data.http.argocd_main_app_yaml.response_body)

  depends_on = [module.helm_release]
}
