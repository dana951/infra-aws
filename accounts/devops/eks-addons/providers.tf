provider "aws" {
  region  = var.aws_region
  profile = var.profile
}

provider "helm" {
  kubernetes = {
    host                   = data.terraform_remote_state.eks_cluster.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.eks_cluster.outputs.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.eks_cluster.token
  }
}
