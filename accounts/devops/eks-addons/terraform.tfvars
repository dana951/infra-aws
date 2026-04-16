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
    addon_version = null
    irsa = {
      k8s_service_account = "efs-csi-controller-sa"
      policy_arn          = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
    }
  }

  "aws-ebs-csi-driver" = {
    enabled       = true
    addon_version = null
    irsa = {
      k8s_service_account = "ebs-csi-controller-sa"
      policy_arn          = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    }
  }
}

helm_charts = {
  "aws-load-balancer-controller" = {
    enabled       = true
    namespace     = "kube-system"
    repository    = "https://aws.github.io/eks-charts"
    chart         = "aws-load-balancer-controller"
    chart_version = "1.14.0"
    values = ["values/aws-load-balancer-controller.yaml"]

    irsa = {
      k8s_service_account = "aws-load-balancer-controller"
      policy_document_url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.14.1/docs/install/iam_policy.json"
    }
  }
}
