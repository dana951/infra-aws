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
  description = "The three availability zones used for subnets."
  value       = local.selected_availability_zones
}

output "public_subnet_ids" {
  description = "Map of public subnet keys to subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Map of private subnet keys to subnet IDs."
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids_by_az" {
  description = "Availability zone to public subnet ID."
  value       = module.vpc.public_subnet_ids_by_az
}

output "private_subnet_ids_by_az" {
  description = "Availability zone to private subnet ID."
  value       = module.vpc.private_subnet_ids_by_az
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
  description = "Public subnet key where the NAT gateway is deployed."
  value       = module.vpc.nat_gateway_subnet_key
}
