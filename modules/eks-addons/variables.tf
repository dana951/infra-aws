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

variable "enable_efs_csi_driver" {
  type        = bool
  description = "Whether to install the aws-efs-csi-driver EKS addon and create its IRSA role."
  default     = true
}

variable "efs_csi_addon_version" {
  type        = string
  description = "Optional aws-efs-csi-driver addon version. Null lets EKS install the default compatible version."
  default     = null
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags merged into all resources created by this module."
  default     = {}
}
