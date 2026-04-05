locals {
  # Stable keys for subnets and for nat_gateway_public_subnet_key (e.g. "a" = first AZ returned).
  subnet_keys = ["a", "b", "c"]

  selected_availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)

  public_subnets = {
    for idx in range(3) : local.subnet_keys[idx] => {
      availability_zone = local.selected_availability_zones[idx]
      cidr_block        = var.public_subnet_cidrs[idx]
    }
  }

  private_subnets = {
    for idx in range(3) : local.subnet_keys[idx] => {
      availability_zone = local.selected_availability_zones[idx]
      cidr_block        = var.private_subnet_cidrs[idx]
    }
  }
}

module "vpc" {
  source = "../../../modules/vpc"

  name_prefix     = var.name_prefix
  vpc_cidr_block  = var.vpc_cidr_block
  cluster_name    = var.cluster_name
  common_tags     = var.common_tags

  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  nat_gateway_public_subnet_key = var.nat_gateway_public_subnet_key

  map_public_ip_on_launch = var.map_public_ip_on_launch

  vpc_tags            = var.vpc_tags
  public_subnet_tags  = var.public_subnet_tags
  private_subnet_tags = var.private_subnet_tags
}
