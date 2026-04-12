locals {
  selected_availability_zones = data.aws_availability_zones.available.names

  public_subnets = {
    for idx, cidr in var.public_subnet_cidrs : tostring(idx + 1) => {
      availability_zone = element(local.selected_availability_zones, idx)
      cidr_block        = cidr
    }
  }

  private_subnets = {
    for idx, cidr in var.private_subnet_cidrs : tostring(idx + 1) => {
      availability_zone = element(local.selected_availability_zones, idx)
      cidr_block        = cidr
    }
  }
}

module "vpc" {
  source = "../../../modules/vpc"

  name_prefix    = var.name_prefix
  vpc_cidr_block = var.vpc_cidr_block
  common_tags    = var.common_tags

  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  create_nat_gateway = var.create_nat_gateway

  map_public_ip_on_launch = var.map_public_ip_on_launch

  vpc_tags            = var.vpc_tags
  public_subnet_tags  = var.public_subnet_tags
  private_subnet_tags = var.private_subnet_tags
}
