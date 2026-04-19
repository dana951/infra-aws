variable "name_prefix" {
  type        = string
  description = "Prefix for Name tags."
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name (used for tagging IAM resources)."
}

variable "oidc_provider_arn" {
  type        = string
  description = "OIDC provider ARN associated with the EKS cluster."
}

variable "oidc_issuer_hostpath" {
  type        = string
  description = "OIDC issuer hostpath (without https://)"
}

variable "helm_charts" {
  type = map(object({
    enabled             = optional(bool, false)
    namespace           = optional(string, "default")
    repository          = string
    chart               = string
    chart_version       = optional(string)
    create_namespace    = optional(bool, false)
    values              = optional(list(string), [])
    set = optional(list(object({
      name  = string
      value = string
      type  = optional(string)
    })), [])
    set_sensitive = optional(list(object({
      name  = string
      value = string
      type  = optional(string)
    })), [])
    wait                = optional(bool, true)
    timeout             = optional(number, 600)
    atomic              = optional(bool, true)
    cleanup_on_fail     = optional(bool, true)
    dependency_update   = optional(bool, false)
    irsa = optional(object({
      k8s_service_account = string
      policy_document_url = string
      role_arn_set_name   = optional(string, "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn")
    }))
  }))
  description = <<-EOT
    Map of Helm releases keyed by release name. This module installs each enabled chart.
    Optional irsa block creates an IAM role, downloads policy JSON from policy_document_url,
    creates an IAM policy, and attaches it to the role.
    IMPORTANT: If irsa is configured, the service account name used by the Helm chart
    must be exactly the same as irsa.k8s_service_account.
  EOT
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags merged into all resources created by this module."
  default     = {}
}
