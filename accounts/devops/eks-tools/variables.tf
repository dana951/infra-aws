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

variable "helm_charts" {
  type        = any
  description = "Helm charts map keyed by release name. Use values as a list of paths relative to this stack (e.g. values/jenkins-values.yaml)."
  default     = {}
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags merged into all resources."
  default     = {}
}
