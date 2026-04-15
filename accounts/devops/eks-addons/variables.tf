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

variable "common_tags" {
  type        = map(string)
  description = "Common tags merged into all resources."
  default     = {}
}

variable "addons" {
  type        = any
  description = "Addons map keyed by addon name, each value contains addon attributes."
  default     = {}
}

variable "helm_charts" {
  type        = any
  description = "Helm charts map keyed by release name, each value contains chart attributes."
  default     = {}
}
