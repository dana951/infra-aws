output "cluster_id" {
  description = "EKS cluster ID."
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = module.eks.cluster_arn
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version."
  value       = module.eks.cluster_version
}

output "cluster_endpoint" {
  description = "EKS API endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded cluster CA data."
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_oidc_issuer_url" {
  description = "Cluster OIDC issuer URL."
  value       = module.eks.cluster_oidc_issuer_url
}

output "cluster_iam_role_name" {
  description = "EKS cluster IAM role name."
  value       = module.eks.cluster_iam_role_name
}

output "cluster_iam_role_arn" {
  description = "EKS cluster IAM role ARN."
  value       = module.eks.cluster_iam_role_arn
}

output "cluster_security_group_id" {
  description = "Security group ID created by EKS."
  value       = module.eks.cluster_security_group_id
}

output "private_node_groups" {
  description = "Private node groups with id/arn/status/version."
  value       = module.eks.private_node_groups
}
