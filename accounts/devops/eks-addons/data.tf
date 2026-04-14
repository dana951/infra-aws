data "terraform_remote_state" "eks_cluster" {
  backend = "local"

  config = {
    path = "${path.root}/../eks-platform/terraform.tfstate"
  }
}

data "aws_eks_cluster_auth" "eks_cluster" {
  name = data.terraform_remote_state.eks_cluster.outputs.cluster_name
}
