provider "aws" {
  region  = var.aws_region
  profile = var.profile
}

data "aws_eks_cluster_auth" "eks_cluster" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.eks_cluster.token
}
