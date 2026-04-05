# Local environment values (gitignored). Keep in sync with terraform.tfvars.example for structure.

aws_region = "us-east-1"

profile = "devops"

name_prefix = "devops-network"

vpc_cidr_block = "10.0.0.0/16"

public_subnets = {
  a = {
    availability_zone = "us-east-1a"
    cidr_block        = "10.0.1.0/24"
  }
  b = {
    availability_zone = "us-east-1b"
    cidr_block        = "10.0.2.0/24"
  }
  c = {
    availability_zone = "us-east-1c"
    cidr_block        = "10.0.3.0/24"
  }
}

private_subnets = {
  a = {
    availability_zone = "us-east-1a"
    cidr_block        = "10.0.10.0/24"
  }
  b = {
    availability_zone = "us-east-1b"
    cidr_block        = "10.0.20.0/24"
  }
  c = {
    availability_zone = "us-east-1c"
    cidr_block        = "10.0.30.0/24"
  }
}

nat_gateway_public_subnet_key = "a"

cluster_name = "devops-eks"

common_tags = {
  Project     = "devops-portfolio"
  Environment = "devops"
  ManagedBy   = "terraform"
  Component   = "network"
}

enable_dns_support   = true
enable_dns_hostnames = true
map_public_ip_on_launch = false
