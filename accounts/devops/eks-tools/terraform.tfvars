aws_region  = "us-east-1"
profile     = "devops"
name_prefix = "devops"

helm_charts = {
  jenkins = {
    enabled          = true
    namespace        = "jenkins"
    repository       = "https://charts.jenkins.io"
    chart            = "jenkins"
    chart_version    = "5.9.14"
    create_namespace = true
    values           = ["values/jenkins-values.yaml"]
  }

  argocd = {
    enabled          = true
    namespace        = "argocd"
    repository       = "https://argoproj.github.io/argo-helm"
    chart            = "argo-cd"
    chart_version    = "9.5.0"
    create_namespace = true
    values           = ["values/argocd-values.yaml"]
  }
}

common_tags = {
  Project     = "devops-portfolio"
  Environment = "devops"
  ManagedBy   = "terraform"
  Component   = "eks-tools"
}
