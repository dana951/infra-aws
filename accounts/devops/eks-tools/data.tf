data "terraform_remote_state" "eks_cluster" {
  backend = "local"

  config = {
    path = "${path.module}/../eks/terraform.tfstate"
  }
}

data "aws_eks_cluster_auth" "eks_cluster" {
  name = data.terraform_remote_state.eks_cluster.outputs.cluster_name
}

data "http" "argocd_main_app_yaml" {
  url = "https://raw.githubusercontent.com/dana951/argocd-apps/main/main-app.yaml"
}
