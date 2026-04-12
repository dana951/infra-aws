module "eks" {
  source = "../../../modules/eks"

  name_prefix  = var.name_prefix
  cluster_name = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id             = data.terraform_remote_state.vpc.outputs.vpc_id
  public_subnet_ids  = data.terraform_remote_state.vpc.outputs.public_subnet_ids
  private_subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids

  cluster_service_ipv4_cidr             = var.cluster_service_ipv4_cidr
  cluster_endpoint_private_access       = var.cluster_endpoint_private_access
  cluster_endpoint_public_access        = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs  = var.cluster_endpoint_public_access_cidrs

  private_node_groups = var.private_node_groups
  public_node_groups  = var.public_node_groups

  common_tags = var.common_tags
}
