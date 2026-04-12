aws_region = "us-east-1"

profile = "devops"

name_prefix = "devops"

vpc_cidr_block = "10.0.0.0/16"

public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24",
  "10.0.3.0/24",
]

private_subnet_cidrs = [
  "10.0.10.0/24",
  "10.0.20.0/24",
  "10.0.30.0/24",
]

create_nat_gateway = true

common_tags = {
  Project     = "devops-portfolio"
  Environment = "devops"
  ManagedBy   = "terraform"
  Component   = "network"
}

enable_dns_support   = true
enable_dns_hostnames = true
map_public_ip_on_launch = false
