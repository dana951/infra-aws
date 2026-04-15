data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "${path.root}/../vpc/terraform.tfstate"
  }
}
