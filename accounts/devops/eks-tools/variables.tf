variable "aws_region" {
  type        = string
  description = "AWS region."
}

variable "profile" {
  type        = string
  description = "AWS profile."
}

variable "name_prefix" {
  type        = string
  description = "Prefix for Name tags."
}

variable "jenkins_namespace" {
  type        = string
  description = "Kubernetes namespace for Jenkins."
  default     = "jenkins"
}

variable "argocd_namespace" {
  type        = string
  description = "Kubernetes namespace for Argo CD."
  default     = "argocd"
}

variable "jenkins_chart_version" {
  type        = string
  description = "Jenkins Helm chart version. Set to null to use latest available."
  default     = null
}

variable "argocd_chart_version" {
  type        = string
  description = "Argo CD Helm chart version."
  default     = null
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags merged into all resources."
  default     = {}
}
