variable "name_prefix" {
  type        = string
  description = "Prefix for Name tags."
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name where addons are installed."
}

variable "cluster_version" {
  type        = string
  description = "EKS cluster Kubernetes version used to resolve compatible addon versions."
}

variable "oidc_provider_arn" {
  type        = string
  description = "OIDC provider ARN associated with the EKS cluster."
}

variable "oidc_issuer_hostpath" {
  type        = string
  description = "OIDC issuer hostpath (without https://)"
}

variable "addons" {
  type = map(object({
    enabled                     = optional(bool, true)
    addon_version               = optional(string)
    configuration_values        = optional(string)
    resolve_conflicts_on_create = optional(string, "OVERWRITE")
    resolve_conflicts_on_update = optional(string, "OVERWRITE")
    preserve                    = optional(bool, false)
    tags                        = optional(map(string), {})
    irsa = object({
      k8s_service_account = string
      policy_arn          = string
    })
  }))
  description = <<-EOT
    Map of EKS addons keyed by addon name (for example aws-efs-csi-driver, coredns, vpc-cni).
    Each addon can override version and related attributes. Required irsa block lets this
    module create IAM role + policy attachments and auto-wire service_account_role_arn.
    If addon_version is not provided for a specific addon, the most recent compatible
    addon version for the given cluster_version is selected automatically.
    Empty map means no addons.
  EOT
  default = {}
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags merged into all resources created by this module."
  default     = {}
}

variable "helm_charts" {
  type = map(object({
    enabled          = optional(bool, true)
    namespace        = optional(string, "default")
    repository       = string
    chart            = string
    chart_version    = optional(string)
    create_namespace = optional(bool, false)
    values           = optional(list(string), [])
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
    wait             = optional(bool, true)
    timeout          = optional(number, 600)
    atomic           = optional(bool, false)
    cleanup_on_fail  = optional(bool, true)
    dependency_update = optional(bool, false)
    irsa = optional(object({
      k8s_service_account = string
      policy_document_url = string
      role_arn_set_name   = optional(string, "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn")
    }))
  }))
  description = <<-EOT
    Map of Helm releases keyed by release name. This module installs each enabled chart.
    Optional irsa block creates an IAM role and policy attachment for the chart service account.
    IMPORTANT: If irsa is configured, the service account name used by the Helm chart
    must be exactly the same as irsa.k8s_service_account.
  EOT
  default = {}
}
