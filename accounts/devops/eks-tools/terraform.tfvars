aws_region  = "us-east-1"
profile     = "devops"
name_prefix = "devops"

jenkins_namespace = "jenkins"
argocd_namespace  = "argocd"

jenkins_chart_version = "5.9.14"
argocd_chart_version = "9.5.0"

common_tags = {
  Project     = "devops-portfolio"
  Environment = "devops"
  ManagedBy   = "terraform"
  Component   = "eks-tools"
}
