variable "name_prefix" {
  type        = string
  description = "Prefix for Name tags."
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name where addons are installed."
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
    Empty map means no addons.
  EOT
  default = {}
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags merged into all resources created by this module."
  default     = {}
}
