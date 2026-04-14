aws_region  = "us-east-1"
profile     = "devops"
name_prefix = "devops"

common_tags = {
  Project     = "devops-portfolio"
  Environment = "devops"
  ManagedBy   = "terraform"
  Component   = "eks-addons"
}

addons = {
  "aws-efs-csi-driver" = {
    enabled       = true
    addon_version = "v2.1.9-eksbuild.1"
    irsa = {
      k8s_service_account = "efs-csi-controller-sa"
      policy_arn          = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
    }
  }
}
