locals {
  helm_charts_with_loaded_values = {
    for release_name, chart in var.helm_charts : release_name => merge(
      chart,
      {
        values = [for values_file in lookup(chart, "values", []) : file("${path.module}/${values_file}")]
      },
    )
  }

  argocd_enabled    = try(var.helm_charts.argocd.enabled, false)
  jenkins_agents_ns = "jenkins-agents"
}

module "helm_release" {
  source = "../../../modules/helm-release"

  name_prefix          = var.name_prefix
  cluster_name         = data.terraform_remote_state.eks_cluster.outputs.cluster_name
  oidc_provider_arn    = data.terraform_remote_state.eks_cluster.outputs.oidc_provider_arn
  oidc_issuer_hostpath = data.terraform_remote_state.eks_cluster.outputs.oidc_issuer_hostpath
  common_tags          = var.common_tags

  helm_charts = local.helm_charts_with_loaded_values

  depends_on = [
    kubernetes_storage_class_v1.ebs_csi,
    kubernetes_namespace_v1.jenkins_agents,
  ]
}

resource "kubernetes_manifest" "argocd_main_app" {
  count = local.argocd_enabled ? 1 : 0

  manifest = yamldecode(data.http.argocd_main_app_yaml.response_body)

  depends_on = [module.helm_release]
}

resource "kubernetes_storage_class_v1" "ebs_csi" {
  metadata {
    name = "ebs-csi"
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete" # Retain (for production)
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
    fsType    = "ext4"
  }
}

resource "kubernetes_namespace_v1" "jenkins_agents" {
  metadata {
    name = local.jenkins_agents_ns
  }
}