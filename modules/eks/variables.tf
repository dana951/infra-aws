variable "name_prefix" {
  type        = string
  description = "Prefix for Name tags."
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name."
}

variable "cluster_version" {
  type        = string
  description = "EKS cluster version (for example 1.35)."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where EKS is deployed."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs."
  default     = []
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs. Private subnets must span at least two distinct AZs for EKS cross-account ENIs."
}

variable "cluster_service_ipv4_cidr" {
  type        = string
  description = "Service IPv4 CIDR for the Kubernetes cluster."
}

variable "cluster_endpoint_private_access" {
  type        = bool
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled."
  default     = true
}

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled."
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

variable "cloudwatch_log_retention_days" {
  type        = number
  description = "Retention in days for EKS control-plane logs."
  default     = 7
}

variable "enabled_cluster_log_types" {
  type        = list(string)
  description = "Enabled EKS control-plane logs."
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "public_node_groups" {
  type = map(object({
    instance_types  = optional(list(string), ["t3.medium"])
    min_size        = number
    max_size        = number
    desired_size    = number
    disk_size       = optional(number, 20)
    max_unavailable = optional(number, 1)
    labels          = optional(map(string), {})
    tags            = optional(map(string), {})
  }))
  description = "Optional public node groups. Empty map means no public node groups. key is the node group name."
  default     = {}
}

variable "private_node_groups" {
  type = map(object({
    instance_types  = optional(list(string), ["t3.medium"])
    min_size        = number
    max_size        = number
    desired_size    = number
    disk_size       = optional(number, 20)
    max_unavailable = optional(number, 1)
    labels          = optional(map(string), {})
    tags            = optional(map(string), {})
  }))
  description = "Optional private node groups. Empty map means no private node groups. key is the node group name."
  default     = {}
}

variable "namespaces" {
  type        = map(string)
  description = "Kubernetes namespaces to create after the EKS cluster is provisioned."
  default     = {}
}

