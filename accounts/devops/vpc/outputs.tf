output "vpc_id" {
  description = "ID of the DevOps VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "IPv4 CIDR block of the DevOps VPC."
  value       = module.vpc.vpc_cidr_block
}

output "vpc_arn" {
  description = "ARN of the DevOps VPC."
  value       = module.vpc.vpc_arn
}

output "internet_gateway_id" {
  description = "Internet Gateway attached to the VPC."
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_id" {
  description = "NAT gateway ID (single NAT deployment)."
  value       = module.vpc.nat_gateway_id
}

output "nat_gateway_public_ip" {
  description = "Elastic IP associated with the NAT gateway."
  value       = module.vpc.nat_gateway_public_ip
}

output "availability_zones" {
  description = "Availability zones available for this region."
  value       = local.selected_availability_zones
}

output "public_subnets" {
  description = "Map of public subnet identifier to details (name, id, az, cidr)."
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Map of private subnet identifier to details (name, id, az, cidr)."
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.vpc.private_subnet_ids
}

output "public_route_table_id" {
  description = "Route table ID for public subnets (default route via Internet Gateway)."
  value       = module.vpc.public_route_table_id
}

output "private_route_table_id" {
  description = "Route table ID for private subnets (default route via NAT gateway)."
  value       = module.vpc.private_route_table_id
}

output "nat_gateway_subnet_key" {
  description = "Public subnet key where the NAT gateway is deployed (null when NAT is disabled)."
  value       = module.vpc.nat_gateway_subnet_key
}
