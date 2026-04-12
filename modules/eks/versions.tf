terraform {
  required_version = ">= 1.14.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.39.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.2.1"
    }
  }
}
