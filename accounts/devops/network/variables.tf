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

variable "public_subnets" {
  type = map(object({
    availability_zone = string
    cidr_block        = string
  }))
  description = <<-EOT
    Public subnets for internet-facing load balancer.
    Keys must include the subnet used for the single NAT gateway (see nat_gateway_public_subnet_key).
  EOT
}

variable "private_subnets" {
  type = map(object({
    availability_zone = string
    cidr_block        = string
  }))
  description = "Private subnets for EKS nodes."
}

variable "nat_gateway_public_subnet_key" {
  type        = string
  description = "Public subnet key where the single NAT gateway is placed (cost tradeoff: one NAT, typically first AZ)."
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
