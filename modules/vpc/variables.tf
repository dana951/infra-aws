variable "name_prefix" {
  type        = string
  description = "Prefix used for resource Name tags."
}

variable "vpc_cidr_block" {
  type        = string
  description = "IPv4 CIDR block for the VPC."
}

variable "enable_dns_support" {
  type        = bool
  description = "Whether DNS resolution is supported for the VPC."
  default     = true
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "Whether instances launched in the VPC receive public DNS hostnames."
  default     = false
}

variable "instance_tenancy" {
  type        = string
  description = "Tenancy option: default or dedicated."
  default     = "default"
}

variable "public_subnets" {
  type = map(object({
    availability_zone = string
    cidr_block        = string
  }))
  description = <<-EOT
    Map of public subnet identifiers (keys) to availability zone and CIDR.
    Keys are arbitrary but stable (e.g. a, b, c); used in resource names and outputs.
  EOT

  validation {
    condition     = length(var.public_subnets) > 0
    error_message = "At least one public subnet is required."
  }
}

variable "private_subnets" {
  type = map(object({
    availability_zone = string
    cidr_block        = string
  }))
  description = <<-EOT
    Map of private subnet identifiers to availability zone and CIDR.
    Typically one per AZ for EKS worker nodes and internal load balancers.
  EOT

  validation {
    condition     = length(var.private_subnets) > 0
    error_message = "At least one private subnet is required."
  }
}

variable "create_nat_gateway" {
  type        = bool
  description = "Whether to create a single NAT gateway."
  default     = true
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to all resources in this module."
  default     = {}
}

variable "public_subnet_tags" {
  type        = map(string)
  description = "Extra tags merged into public subnets only."
  default     = {}
}

variable "private_subnet_tags" {
  type        = map(string)
  description = "Extra tags merged into private subnets only."
  default     = {}
}

variable "vpc_tags" {
  type        = map(string)
  description = "Extra tags merged into the VPC resource only."
  default     = {}
}

variable "map_public_ip_on_launch" {
  type        = bool
  description = "Whether instances in public subnets receive a public IP by default."
  default     = false
}
