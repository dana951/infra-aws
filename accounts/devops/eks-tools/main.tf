module "helm_release" {
  source = "../../../modules/helm-release"

  name_prefix          = var.name_prefix
  cluster_name         = data.terraform_remote_state.eks_cluster.outputs.cluster_name
  oidc_provider_arn    = data.terraform_remote_state.eks_cluster.outputs.oidc_provider_arn
  oidc_issuer_hostpath = data.terraform_remote_state.eks_cluster.outputs.oidc_issuer_hostpath
  common_tags          = var.common_tags

  helm_charts = {
    jenkins = {
      enabled          = true
      namespace        = var.jenkins_namespace
      repository       = "https://charts.jenkins.io"
      chart            = "jenkins"
      chart_version    = var.jenkins_chart_version
      create_namespace = true
      values           = [file("${path.module}/values/jenkins-values.yaml")]
    }

    argocd = {
      enabled          = true
      namespace        = var.argocd_namespace
      repository       = "https://argoproj.github.io/argo-helm"
      chart            = "argo-cd"
      chart_version    = var.argocd_chart_version
      create_namespace = true
      values           = [file("${path.module}/values/argocd-values.yaml")]
    }
  }
}
