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

  # ToDo - Patch for now, explicitly create the argocd namespace
  # instead of waiting for the argocd helm chart to create the namespace
  # This is because in this POC Jenkins check argocd Application helth via
  # kubectl instead of using argocd cli
  # Fix to prouction - wire secret manager mechanism for handle secrets
  # (argocd token for Jenkins to use for accessing argocd api) 
  argocd_ns = "argocd"

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

# ToDo - Need to Move this to new terraform folder
# terraform apply fails because it check Argo CD Application 
# CRD before it install the Argo CD Helm chart - race condition
# We shell not install argocd and creae Application manifest in same terraform state
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

# ToDo - Patch for now, explicitly create the argocd namespace
# See comments in local.argocd_ns
resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = local.argocd_ns
  }
}