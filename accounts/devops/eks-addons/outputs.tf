output "enabled_addons" {
  description = "Enabled EKS addons with arn/version/status."
  value       = module.eks_addons.enabled_addons
}

output "addon_irsa_roles" {
  description = "IAM roles created for addon IRSA."
  value       = module.eks_addons.addon_irsa_roles
}

output "enabled_helm_charts" {
  description = "Enabled Helm releases with name/namespace/status/version."
  value       = module.eks_addons.enabled_helm_charts
}

output "helm_chart_irsa_roles" {
  description = "IAM roles created for Helm chart IRSA."
  value       = module.eks_addons.helm_chart_irsa_roles
}
