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
  description = "Prefix for Name tags and logical naming."
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name."
}

variable "cluster_version" {
  type        = string
  description = "EKS cluster version."
}

variable "cluster_service_ipv4_cidr" {
  type        = string
  description = "Service IPv4 CIDR for Kubernetes services."
}

variable "cluster_endpoint_private_access" {
  type        = bool
  description = "Whether private API endpoint is enabled."
  default     = true
}

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "Whether public API endpoint is enabled."
  default     = false
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint."
  default     = []
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags merged into all resources."
  default     = {}
}
