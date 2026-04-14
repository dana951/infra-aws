data "terraform_remote_state" "eks_cluster" {
  backend = "local"

  config = {
    path = "${path.root}/../eks-platform/terraform.tfstate"
  }
}
