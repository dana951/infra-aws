module "vpc" {
  source = "../../../modules/vpc"

  name_prefix     = var.name_prefix
  vpc_cidr_block  = var.vpc_cidr_block
  cluster_name    = var.cluster_name
  common_tags     = var.common_tags

  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  nat_gateway_public_subnet_key = var.nat_gateway_public_subnet_key

  map_public_ip_on_launch = var.map_public_ip_on_launch

  vpc_tags            = var.vpc_tags
  public_subnet_tags  = var.public_subnet_tags
  private_subnet_tags = var.private_subnet_tags
}
