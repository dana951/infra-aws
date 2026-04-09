variable "aws_region" {
  type        = string
  description = "AWS region."
}

variable "profile" {
  type        = string
  description = "AWS CLI profile."
}

variable "name_prefix" {
  type        = string
  description = "Prefix for resource Name tags."
}

variable "vpc_cidr_block" {
  type        = string
  description = "IPv4 CIDR for the VPC."
}

variable "enable_dns_support" {
  type        = bool
  description = "Enable DNS resolution in the VPC."
  default     = true
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "Enable DNS hostnames in the VPC."
  default     = true
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDR blocks."

  validation {
    condition     = length(var.public_subnet_cidrs) > 0
    error_message = "At least one public subnet CIDR block is required."
  }
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDR blocks."

  validation {
    condition     = length(var.private_subnet_cidrs) > 0
    error_message = "At least one private subnet CIDR block is required."
  }
}

variable "create_nat_gateway" {
  type        = bool
  description = "Whether to create a single NAT gateway."
  default     = true
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name for kubernetes.io/cluster/<name> subnet tags (must match the future EKS cluster resource name)."
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags merged into all resources created by the VPC module."
  default     = {}
}

variable "map_public_ip_on_launch" {
  type        = bool
  description = "Whether instances in public subnets get a public IP by default."
  default     = false
}

variable "vpc_tags" {
  type        = map(string)
  description = "Additional tags applied only to the VPC resource."
  default     = {}
}

variable "public_subnet_tags" {
  type        = map(string)
  description = "Additional tags merged into public subnets only."
  default     = {}
}

variable "private_subnet_tags" {
  type        = map(string)
  description = "Additional tags merged into private subnets only."
  default     = {}
}
