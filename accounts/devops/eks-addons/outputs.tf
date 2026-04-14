output "enabled_addons" {
  description = "Enabled EKS addons with arn/version/status."
  value       = module.eks_addons.enabled_addons
}

output "addon_irsa_roles" {
  description = "IAM roles created for addon IRSA."
  value       = module.eks_addons.addon_irsa_roles
}
