output "cluster_id" {
  description = "The EKS cluster ID."
  value       = aws_eks_cluster.eks_cluster.id
}

output "cluster_name" {
  description = "The EKS cluster name."
  value       = aws_eks_cluster.eks_cluster.name
}

output "cluster_arn" {
  description = "The EKS cluster ARN."
  value       = aws_eks_cluster.eks_cluster.arn
}

output "cluster_version" {
  description = "The EKS cluster Kubernetes version."
  value       = aws_eks_cluster.eks_cluster.version
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS Kubernetes API."
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate authority data for the cluster."
  value       = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the EKS cluster."
  value       = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

output "oidc_issuer_hostpath" {
  description = "OIDC issuer hostpath without https://."
  value       = replace(aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN."
  value       = aws_iam_openid_connect_provider.oidc_provider.arn
}

output "node_group_role_arn" {
  description = "IAM role ARN used by EKS managed node groups."
  value       = aws_iam_role.eks_nodegroup_role.arn
}

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster."
  value       = aws_iam_role.eks_master_role.name
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster."
  value       = aws_iam_role.eks_master_role.arn
}

output "cluster_security_group_id" {
  description = "Security group ID created by EKS."
  value       = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

output "private_node_groups" {
  description = "Private node groups keyed by node group name."
  value = {
    for name, ng in aws_eks_node_group.private : name => {
      id      = ng.id
      arn     = ng.arn
      status  = ng.status
      version = ng.version
    }
  }
}

output "public_node_groups" {
  description = "Public node groups keyed by node group name."
  value = {
    for name, ng in aws_eks_node_group.public : name => {
      id      = ng.id
      arn     = ng.arn
      status  = ng.status
      version = ng.version
    }
  }
}
