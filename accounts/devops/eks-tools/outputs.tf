output "enabled_helm_charts" {
  description = "Enabled Helm releases with name/namespace/status/version."
  value       = module.helm_release.enabled_helm_charts
}

output "helm_chart_irsa_roles" {
  description = "IAM roles created for Helm chart IRSA."
  value       = module.helm_release.helm_chart_irsa_roles
}
