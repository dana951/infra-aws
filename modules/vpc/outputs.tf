output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.vpc.id
}

output "vpc_cidr_block" {
  description = "IPv4 CIDR block of the VPC."
  value       = aws_vpc.vpc.cidr_block
}

output "vpc_arn" {
  description = "ARN of the VPC."
  value       = aws_vpc.vpc.arn
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.aws_igw.id
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway (single NAT deployment)."
  value       = aws_nat_gateway.nat_gateway.id
}

output "nat_gateway_public_ip" {
  description = "Public IP address of the NAT gateway (from the associated Elastic IP)."
  value       = aws_eip.eip.public_ip
}

output "public_subnet_ids" {
  description = "Map of public subnet keys to subnet IDs."
  value       = { for k, s in aws_subnet.public_subnet : k => s.id }
}

output "private_subnet_ids" {
  description = "Map of private subnet keys to subnet IDs."
  value       = { for k, s in aws_subnet.private_subnet : k => s.id }
}

output "public_subnet_ids_list" {
  description = "List of public subnet IDs (order not guaranteed; prefer keyed maps for AZ alignment)."
  value       = values(aws_subnet.public_subnet)[*].id
}

output "private_subnet_ids_list" {
  description = "List of private subnet IDs (order not guaranteed)."
  value       = values(aws_subnet.private_subnet)[*].id
}

output "public_subnet_ids_by_az" {
  description = "Map of availability zone to public subnet ID (fails if multiple subnets share the same AZ)."
  value       = { for k, s in aws_subnet.public_subnet : s.availability_zone => s.id }
}

output "private_subnet_ids_by_az" {
  description = "Map of availability zone to private subnet ID (fails if multiple subnets share the same AZ)."
  value       = { for k, s in aws_subnet.private_subnet : s.availability_zone => s.id }
}

output "public_route_table_id" {
  description = "ID of the public route table (Internet Gateway default route)."
  value       = aws_route_table.public_rt.id
}

output "private_route_table_id" {
  description = "ID of the private route table (NAT gateway default route)."
  value       = aws_route_table.private_rt.id
}

output "nat_gateway_subnet_key" {
  description = "Public subnet key where the NAT gateway is deployed."
  value       = var.nat_gateway_public_subnet_key
}
